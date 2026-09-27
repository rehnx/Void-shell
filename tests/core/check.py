"""Run with dbus-run-session -- python3 tests/core/check.py."""
import json
import pathlib
import subprocess
import tempfile
import time


ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "shell" / "core-test.qml"


def call(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=5).strip()


def ipc(method, *args):
    encoded = [(str(value).lower() if isinstance(value, bool) else str(value)) for value in args]
    return call("qs", "ipc", "--pid", str(shell.pid), "call", "coreTest", method,
                *encoded)


def state(method="state", *args):
    return json.loads(ipc(method, *args))


def eventually(predicate, timeout=5):
    until = time.monotonic() + timeout
    while time.monotonic() < until:
        try:
            if predicate():
                return
        except (subprocess.SubprocessError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    raise AssertionError("Core state did not reach expected value: " + str(state()))


with tempfile.TemporaryFile(mode="w+") as log:
    shell = subprocess.Popen(["qs", "-p", str(CONFIG)], stdout=log, stderr=log)
    try:
        eventually(lambda: state()["memory"] > 0)
        stats = state("refreshStats")
        assert 0 <= stats["cpu"] <= 1
        assert 0 < stats["memory"] <= 1
        if stats["temperatureAvailable"]:
            assert stats["temperature"] > 0
        else:
            assert stats["temperature"] == 0
        if stats["batteryAvailable"]:
            assert 0 <= stats["batteryPercentage"] <= 1
            assert stats["batteryStatus"] != "Unavailable"
        else:
            assert stats["batteryPercentage"] == 0
            assert stats["batteryStatus"] == "Unavailable"
        if stats["brightnessAvailable"]:
            assert 0 <= stats["brightnessValue"] <= 1
        else:
            assert stats["brightnessStatus"] == "Unavailable"
        print("PASS CPU, RAM, optional temperature, battery and brightness states")

        initial = state("currentMonth")
        assert initial["month"] == initial["todayMonth"]
        assert initial["year"] == initial["todayYear"]
        assert initial["todayCells"] == 1
        previous = state("previousMonth")
        assert (previous["year"] * 12 + previous["month"]
                == initial["year"] * 12 + initial["month"] - 1)
        following = state("nextMonth")
        assert (following["year"], following["month"]) == (initial["year"], initial["month"])
        print("PASS current-day calendar and previous/next month navigation")

        for action in ("shutdown", "reboot", "logout"):
            requested = state("requestPower", action)
            assert requested["pendingAction"] == action
            assert requested["powerOpened"]
            assert requested["lastPowerAction"] == ""
            confirmed = state("confirmPower")
            assert confirmed["pendingAction"] == ""
            assert not confirmed["powerOpened"]
            assert confirmed["lastPowerAction"] == action
        cancelled = state("requestPower", "shutdown")
        assert cancelled["pendingAction"] == "shutdown"
        cancelled = state("cancelPower")
        assert cancelled["lastPowerAction"] == "" and cancelled["pendingAction"] == ""
        for action in ("lock", "suspend"):
            requested = state("requestPower", action)
            assert requested["lastPowerAction"] == action
            assert requested["pendingAction"] == "" and not requested["powerOpened"]
        print("PASS power confirmation and safe action dispatch (execution disabled)")

        shown = state("showOsd", "volume", "Volume", 0.42, False)
        assert shown["osdVisible"] and shown["osdKind"] == "volume"
        assert shown["osdLabel"] == "Volume" and abs(shown["osdValue"] - 0.42) < 0.01
        shown = state("showOsd", "brightness", "Brightness", 0.65, False)
        assert shown["osdVisible"] and shown["osdKind"] == "brightness"
        assert abs(shown["osdValue"] - 0.65) < 0.01
        time.sleep(1)
        state("showOsd", "microphone", "Microphone", 0.8, True)
        time.sleep(0.8)
        assert state()["osdVisible"]
        eventually(lambda: not state()["osdVisible"], timeout=2)
        eventually(lambda: not state()["osdWindowVisible"], timeout=2)
        print("PASS reusable OSD data, timer reset, fade and automatic dismissal")

        assert ipc("panelInteractions") == "passed"
        print("PASS Escape and outside-click handling for floating panels")
    finally:
        shell.terminate()
        shell.wait(timeout=5)
        log.seek(0)
        output = log.read()
        if "ERROR" in output or "WARN scene" in output:
            print(output)
            raise AssertionError("Quickshell runtime error")
