"""Exercise motion on a private bus in a running Wayland session."""
import pathlib
import os
import subprocess
import tempfile
import time
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

with tempfile.TemporaryFile(mode="w+") as log:
    shell = subprocess.Popen(
        ["qs", "-p", str(ROOT / "shell/motion-test.qml")], stdout=log, stderr=log
    )

    def ipc(method, *args):
        return subprocess.check_output(
            ["qs", "ipc", "--pid", str(shell.pid), "call", "motionTest", method, *args],
            text=True, stderr=subprocess.STDOUT, timeout=55,
        ).strip()

    try:
        deadline = time.monotonic() + 10
        while True:
            try:
                assert ipc("ready") == "ready"
                break
            except (subprocess.SubprocessError, AssertionError):
                if shell.poll() is not None or time.monotonic() > deadline:
                    raise
                time.sleep(0.1)
        checks = tuple(sys.argv[1:]) or ("panels", "interactions", "contextual", "toasts", "configuration", "themes")
        if os.environ.get("VOID_MOTION_CAPTURE_DIR"):
            checks += ("visual",)
        for name in checks:
            result = ipc("run", name)
            assert result == "passed", f"{name}: {result}"
            print(f"PASS {name}", flush=True)
    finally:
        shell.terminate()
        shell.wait(timeout=5)
        log.seek(0)
        output = log.read()
        problems = [line for line in output.splitlines()
                    if "ERROR" in line or "WARN scene" in line or "TypeError" in line]
        if problems:
            print(output)
            raise AssertionError("Quickshell motion runtime errors")
