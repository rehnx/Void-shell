"""Private-bus Developer Center checks; power execution and compositor changes disabled."""
import contextlib
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import time
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "shell/developer-test.qml"
QS = shutil.which("qs")


def eventually(predicate, timeout=10):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        try:
            if predicate():
                return
        except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    raise AssertionError("Developer Center did not reach expected state")


@contextlib.contextmanager
def launch(directory, *, config=CONFIG, overrides=None, expected_errors=()):
    env = {k: v for k, v in os.environ.items() if not k.startswith(("VOID_",))}
    env.update(VOID_SETTINGS_PATH=str(directory / "settings.json"), XDG_STATE_HOME=str(directory / "state"))
    env.update(overrides or {})
    (directory / "settings.json").write_text('{"version":1,"blurStrength":0}')
    with tempfile.TemporaryFile(mode="w+") as log:
        process = subprocess.Popen([QS, "-p", str(config)], stdout=log, stderr=log, env=env)

        def call(target, method, *args):
            return subprocess.check_output([QS, "ipc", "--pid", str(process.pid), "call", target, method,
                *map(str, args)], text=True, stderr=subprocess.STDOUT, timeout=55).strip()

        try:
            eventually(lambda: call("settings", "ready") == "ready")
            yield process, call
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            log.seek(0)
            errors = [line for line in log.read().splitlines() if any(word in line for word in
                ("ERROR", "WARN scene", "TypeError", "ReferenceError", "Binding loop"))]
            errors = [line for line in errors if not any(expected in line for expected in expected_errors)]
            assert not errors, "\n".join(errors)


def cpu_seconds(pid):
    fields = pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf("SC_CLK_TCK")


def helper_checks(directory):
    helpers = directory / "helpers"
    helpers.mkdir()
    (helpers / "sh").symlink_to(shutil.which("sh"))
    mode = helpers / "mode"
    mode.write_text("success")
    script = f"#!{sys.executable}\n" + '''import os
import pathlib
import sys
import time

tool = pathlib.Path(__file__)
with tool.with_suffix(".calls").open("a") as calls:
    calls.write(str(os.getpid()) + "\\n")
mode = (tool.parent / "mode").read_text()
if mode == "slow":
    time.sleep(60)
if mode == "error":
    sys.exit(1)
print("1000 200 800 20% /" if tool.name == "df" else "R\\nS")
'''
    for name in ("df", "ps"):
        (helpers / name).write_text(script)
        (helpers / name).chmod(0o755)

    with launch(directory, overrides={"PATH": str(helpers)}) as (process, call):
        def state():
            return json.loads(call("developerTest", "state"))

        def refresh():
            previous = state()["requested"]
            eventually(lambda: time.time() * 1000 - previous > 1100)
            call("developerTest", "refresh")
            assert state()["requested"] > previous, state()

        def unavailable():
            current = state()
            return not current["busy"] and not current["disks"] and current["processes"] is None

        # Exercise helper lifetimes without an input-sensitive overlay window.
        call("developerTest", "monitoring", "true")
        eventually(lambda: state()["processes"] and state()["disks"] and not state()["busy"])
        assert state()["disks"][0]["usage"] == 0.2 and state()["processes"]["total"] == 2

        # A failed start must discard the previous successful snapshot.
        for name in ("df", "ps"):
            (helpers / name).rename(helpers / (name + ".disabled"))
        refresh()
        eventually(unavailable)
        for name in ("df", "ps"):
            (helpers / (name + ".disabled")).rename(helpers / name)
        mode.write_text("error")
        refresh()
        eventually(unavailable)
        mode.write_text("success")
        refresh()
        eventually(lambda: state()["processes"] and state()["disks"] and not state()["busy"])

        mode.write_text("slow")
        refresh()
        eventually(lambda: all(len((helpers / (name + ".calls")).read_text().splitlines()) == 4
                               for name in ("df", "ps")))
        requested = state()["requested"]
        for _ in range(4):
            call("developerTest", "refresh")
        assert state()["requested"] == requested, "Diagnostic helpers overlapped"
        pids = [int((helpers / (name + ".calls")).read_text().splitlines()[-1]) for name in ("df", "ps")]
        call("developerTest", "monitoring", "false")
        eventually(unavailable, timeout=7)
        assert all(not pathlib.Path(f"/proc/{pid}").exists() for pid in pids), "Timed-out helper survived"
    print("PASS missing/failed helpers, stale snapshot recovery, non-overlapping refresh and timeout", flush=True)


with tempfile.TemporaryDirectory(prefix="void-developer-") as folder:
    directory = pathlib.Path(folder)
    if "--helpers" in sys.argv:
        helper_checks(directory)
        sys.exit(0)
    if "--performance" in sys.argv:
        # Caller supplies an untouched Phase 11 checkout for the same entrypoint.
        baseline_path = os.environ.get("VOID_DEVELOPER_BASELINE") or sys.argv[sys.argv.index("--performance") + 1]
        baseline = pathlib.Path(baseline_path) / "shell/shell.qml"
        samples = []
        for config in (baseline, ROOT / "shell/shell.qml"):
            with launch(directory, config=config) as (process, call):
                time.sleep(3)
                start = cpu_seconds(process.pid)
                elapsed = time.monotonic()
                time.sleep(12)
                percent = (cpu_seconds(process.pid) - start) / (time.monotonic() - elapsed) * 100
                samples.append(percent)
        assert samples[1] <= samples[0] + 1.0, samples
        print(f"PASS closed-shell idle CPU: Phase 11 {samples[0]:.2f}%, Phase 12 {samples[1]:.2f}% of one core")
        sys.exit(0)

    with launch(directory) as (process, call):
        def state():
            return json.loads(call("developerTest", "state"))

        assert not state()["initialized"] and not state()["active"] and state()["requested"] == 0
        call("developerTest", "open", "true")
        eventually(lambda: state()["processes"] and state()["disks"] and state()["uptime"] > 0)
        live = state()
        assert live["hostname"] == pathlib.Path("/proc/sys/kernel/hostname").read_text().strip()
        assert live["kernel"] == pathlib.Path("/proc/sys/kernel/osrelease").read_text().strip()
        assert live["distro"] != "Unavailable" and live["memory"] > 0 and 0 <= live["cpu"] <= 1
        assert live["interval"] == 2000 and live["version"].startswith("0.12.0")
        assert all(path["value"].startswith("/") for path in live["paths"])
        eventually(lambda: state()["uptime"] > live["uptime"], timeout=5)
        eventually(lambda: time.time() * 1000 - live["requested"] >= 1100)
        call("developerTest", "refresh")
        eventually(lambda: state()["requested"] > live["requested"] and not state()["busy"])
        call("developerTest", "open", "false")
        eventually(lambda: not state()["visible"])
        cached = state()["requested"]
        for _ in range(3):
            call("developerTest", "open", "true")
            call("developerTest", "open", "false")
        assert state()["requested"] == cached
        print("PASS shared live stats, native session data, XDG paths, refresh and cached reopen", flush=True)

        if "--visual" in sys.argv:
            capture = pathlib.Path("/tmp/void-phase12-preview.png")
            capture.unlink(missing_ok=True)
            call("developerTest", "capture", str(capture))
            eventually(lambda: capture.exists() and capture.read_bytes().endswith(b"\x00\x00\x00\x00IEND\xaeB\x60\x82"))
            print("PASS preview: " + str(capture), flush=True)
            sys.exit(0)

        for name in ("interactions", "appearance", "motion", "fallbacks"):
            result = call("developerTest", "run", name)
            assert result == "passed", f"{name}: {result}"
            print("PASS " + name, flush=True)

        call("developerTest", "open", "false")
        eventually(lambda: not state()["busy"] and not state()["visible"])
        before = state()
        start = cpu_seconds(process.pid)
        time.sleep(32)
        after = state()
        assert after["interval"] == 5000 and not after["active"]
        assert after["requested"] == before["requested"] and after["uptime"] == before["uptime"]
        print(f"PASS closed panel stops extra reads/helpers; idle {(cpu_seconds(process.pid) - start) / 32 * 100:.2f}% of one core", flush=True)
        if os.environ.get("VOID_DEVELOPER_CAPTURE"):
            call("developerTest", "capture", os.environ["VOID_DEVELOPER_CAPTURE"])
            eventually(lambda: pathlib.Path(os.environ["VOID_DEVELOPER_CAPTURE"]).exists())

    with launch(directory, overrides={"DBUS_SYSTEM_BUS_ADDRESS": "unix:path=/tmp/void-developer-missing-system-bus",
                "PIPEWIRE_REMOTE": "void-developer-missing-pipewire"}, expected_errors=(
                "ERROR quickshell.service.pipewire.loop: Failed to connect pipewire context.",
                "ERROR quickshell.network: Network will not work. Could not find an available backend.")) as (process, call):
        call("developerTest", "open", "true")
        eventually(lambda: json.loads(call("developerTest", "state"))["uptime"] > 0)
        state = json.loads(call("developerTest", "state"))
        assert not state["battery"] and state["network"] == "Unavailable" and state["audio"] == "Unavailable", state
        assert call("developerTest", "run", "fallbacks") == "passed"
    print("PASS missing battery, network, audio and optional data", flush=True)

    helper_checks(directory)

    with launch(directory, config=ROOT / "shell/shell.qml") as (process, call):
        assert call("theme", "current") == "void-dark"
        assert json.loads(call("settings", "get"))["modules"]["developerCenter"]
    print("PASS real shell startup and module registration", flush=True)
