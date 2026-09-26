"""Run on a PRIVATE session bus: dbus-run-session -- python3 tests/notifications/check.py."""
import json
import os
import pathlib
import re
import subprocess
import tempfile
import time
import sys

CONFIG = pathlib.Path(__file__).resolve().parents[2] / "shell" / "notification-test.qml"


def call(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=5).strip()


def ipc(method, *args):
    return call("qs", "ipc", "--pid", str(process.pid), "call", "test", method, *map(str, args))


def state():
    return json.loads(ipc("state"))


def eventually(predicate, timeout=5):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        try:
            if predicate():
                return
        except (subprocess.SubprocessError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for expected notification state")


def dbus(method, *args):
    return call("gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
                "--object-path", "/org/freedesktop/Notifications", "--method",
                "org.freedesktop.Notifications." + method, "--", *map(str, args))


def notify(title="Title", body="Body", replace=0, timeout=0, hints="{}", icon="dialog-information"):
    result = dbus("Notify", "Void Test", replace, icon, title, body, "[]", hints, timeout)
    return int(re.search(r"uint32 (\d+)", result)[1])


with tempfile.TemporaryFile(mode="w+") as log:
    environment = os.environ.copy()
    if "--unavailable" in sys.argv:
        environment["DBUS_SESSION_BUS_ADDRESS"] = "unix:path=/tmp/void-missing-notification-bus"
    process = subprocess.Popen(["qs", "-p", str(CONFIG)], stdout=log, stderr=log, env=environment)
    try:
        eventually(lambda: state()["history"] == [])
        assert ipc("interactions") == "passed"
        print("PASS empty state, Escape, outside/inside clicks")
        if "--unavailable" in sys.argv:
            assert not state()["toastVisible"]
            print("PASS unavailable D-Bus: empty history, no toast, usable panel")
            sys.exit(0)
        ident = notify(body="Plain <b>text</b> & Unicode ✓")
        eventually(lambda: len(state()["history"]) == 1)
        entry = state()["history"][0]
        assert entry["app"] == "Void Test" and entry["title"] == "Title"
        assert entry["body"] == "Plain <b>text</b> & Unicode ✓" and entry["icon"] and entry["time"] > 0
        assert state()["toastVisible"]
        eventually(lambda: float(ipc("toastOpacity")) > 0.95)
        assert notify("Updated", "Replacement", replace=ident) == ident
        eventually(lambda: state()["history"][0]["title"] == "Updated")
        assert len(state()["history"]) == 1
        dbus("CloseNotification", ident)
        eventually(lambda: not state()["history"] and not state()["toasts"])
        print("PASS delivery, metadata, toast, replacement, client close")
        notify(timeout=200)
        eventually(lambda: len(state()["history"]) == 1 and not state()["toasts"])
        assert state()["live"] == 0
        ipc("dismiss", state()["history"][0]["id"])
        assert not state()["history"]
        print("PASS expiry retains history; dismiss removes expired entry")
        notify(timeout=200, hints="{'transient': <true>}")
        eventually(lambda: state()["live"] == 0)
        assert not state()["history"]
        notify(timeout=200, hints="{'urgency': <byte 2>}", icon="")
        time.sleep(0.35)
        assert state()["live"] == 1 and state()["toastVisible"]
        ipc("dismiss", state()["history"][0]["id"])
        assert state()["live"] == 0
        print("PASS transient, critical, missing icon, live dismiss")
        notify()
        assert ipc("dismissCard", "true") == "passed"
        notify()
        assert ipc("dismissCard", "false") == "passed"
        print("PASS toast and history card dismiss wiring")
        for i in range(5):
            notify(str(i))
        assert len(state()["toasts"]) == 3
        ipc("open")
        assert not state()["toasts"] and len(state()["history"]) == 5
        assert ipc("buttons") == "passed"
        assert state()["live"] == 0
        print("PASS toast cap, history opening, clear-all and close buttons")
        for i in range(105):
            notify(str(i))
        assert len(state()["history"]) == 100 and state()["live"] == 100
        ipc("clear")
        assert not state()["history"] and state()["live"] == 0
        print("PASS bounded history and clear-all cleanup")
        notify(timeout=-1)
        assert state()["toastVisible"]
        eventually(lambda: state()["live"] == 0, timeout=8)
        assert len(state()["history"]) == 1
        ipc("clear")
        print("PASS default timeout")
    except Exception:
        print("State at failure:", ipc("state"))
        raise
    finally:
        process.terminate()
        process.wait(timeout=5)
        log.seek(0)
        output = log.read()
        if "ERROR" in output or "WARN scene" in output:
            print(output)
            raise AssertionError("Quickshell runtime errors or QML warnings detected")
