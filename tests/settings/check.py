"""Phase 11: private D-Bus, temporary settings, real panels, fake compositor IPC."""
import contextlib
import json
import os
import pathlib
import socket
import subprocess
import tempfile
import threading
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "shell/settings-test.qml"


def eventually(predicate, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if predicate():
                return
        except (subprocess.SubprocessError, OSError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    raise AssertionError("Timed out waiting for settings state")


class Shell:
    def __init__(self, process):
        self.process = process

    def call(self, target, method, *args):
        return subprocess.check_output(
            ["qs", "ipc", "--pid", str(self.process.pid), "call", target, method, *map(str, args)],
            text=True, stderr=subprocess.STDOUT, timeout=40).strip()

    def settings(self, method, *args):
        return self.call("settings", method, *args)

    def set(self, key, value):
        assert self.settings("set", key, json.dumps(value)) == "ok", key

    def update(self, values):
        assert self.settings("update", json.dumps(values)) == "ok"

    def get(self):
        return json.loads(self.settings("get"))

    def state(self):
        return json.loads(self.call("settingsTest", "state"))

    def run(self, name):
        result = self.call("settingsTest", "run", name)
        assert result == "passed", (name, result, self.get())


@contextlib.contextmanager
def launch(directory, *, config=CONFIG, overrides=None, default_path=False):
    environment = {k: v for k, v in os.environ.items()
                   if not k.startswith(("VOID_THEME", "VOID_SETTINGS", "VOID_MOTION", "VOID_REDUCED", "VOID_WALLPAPER"))}
    environment.update(XDG_STATE_HOME=str(directory / "state"), VOID_TEST_BLUR_SOCKET=str(directory / "blur.sock"))
    if not default_path:
        environment["VOID_SETTINGS_PATH"] = str(directory / "settings.json")
    environment.update(overrides or {})
    with tempfile.TemporaryFile(mode="w+") as log:
        process = subprocess.Popen(["qs", "-p", str(config)], stdout=log, stderr=log, env=environment)
        shell = Shell(process)
        try:
            eventually(lambda: shell.settings("ready") == "ready")
            yield shell
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
            log.seek(0)
            output = log.read()
            problems = [line for line in output.splitlines() if any(word in line for word in
                        ("ERROR", "WARN scene", "TypeError", "ReferenceError", "Binding loop"))]
            assert not problems, "\n".join(problems)


@contextlib.contextmanager
def compositor(directory, replies=None):
    requests = []
    stop = threading.Event()
    with socket.socket(socket.AF_UNIX) as server:
        server.bind(str(directory / "blur.sock"))
        server.listen()
        server.settimeout(0.1)

        def serve():
            while not stop.is_set():
                try:
                    connection, _ = server.accept()
                except socket.timeout:
                    continue
                with connection:
                    connection.settimeout(2)
                    requests.append(connection.recv(4096).decode())
                    reply = replies.pop(0) if replies else b"ok"
                    connection.sendall(reply[:1])
                    time.sleep(0.01)  # Replies can arrive in separate reads.
                    connection.sendall(reply[1:])

        worker = threading.Thread(target=serve, daemon=True)
        worker.start()
        try:
            yield requests
        finally:
            stop.set()
            worker.join(timeout=3)
    (directory / "blur.sock").unlink()


def notify(title):
    subprocess.check_output(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
        "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify",
        "--", "Settings Test", "0", "", title, "Body", "[]", "{}", "0"], text=True, timeout=5)


with tempfile.TemporaryDirectory(prefix="void-settings-") as directory:
    temporary = pathlib.Path(directory)
    state_path = temporary / "settings.json"
    replies = []
    with compositor(temporary, replies) as requests, launch(temporary) as shell:
        defaults = shell.get()
        assert defaults["theme"] == "void-dark" and all(defaults["modules"].values())
        assert shell.settings("flush") == "saved"
        assert json.loads(state_path.read_text())["theme"] == "void-dark"
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "applied")
        assert requests[-1] == "keyword decoration:blur:size 8"
        print("PASS missing config, defaults, atomic persistence and compositor IPC", flush=True)

        # Every setting is changed live and checked at its consumer, not just its store.
        for theme, name in (("void-dark", "Void Dark"), ("void-light", "Void Light"),
                            ("amoled", "AMOLED"), ("warm-glass", "Warm Glass"), ("dynamic", "Wallpaper Dynamic")):
            shell.set("theme", theme)
            assert shell.state()["theme"] == theme and shell.state()["themeName"] == name
        assert shell.call("theme", "setTheme", "light") == "void-light"
        assert shell.get()["theme"] == "void-light"
        shell.set("transparency", 0)
        assert shell.state()["surfaceAlpha"] == 1
        shell.set("transparency", 0.5)
        state = shell.state()
        assert abs(state["surfaceAlpha"] - (1 + state["paletteAlpha"]) / 2) < 0.01
        shell.set("transparency", 1)
        assert abs(shell.state()["surfaceAlpha"] - shell.state()["paletteAlpha"]) < 0.01
        shell.set("blurStrength", 0)
        assert not shell.state()["blurEnabled"]
        shell.set("blurStrength", 12)
        eventually(lambda: requests[-1] == "keyword decoration:blur:size 12")
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "applied")
        replies.append(b"error")
        shell.set("blurStrength", 13)
        eventually(lambda: requests[-1] == "keyword decoration:blur:size 13")
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "unavailable")
        shell.set("blurStrength", 14)
        eventually(lambda: requests[-1] == "keyword decoration:blur:size 14")
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "applied")
        shell.set("theme", "amoled")
        assert not shell.state()["blurEnabled"]
        shell.set("theme", "warm-glass")
        assert shell.state()["blurEnabled"]
        shell.set("cornerRadius", 0)
        assert shell.state()["radius"] == 0
        shell.set("density", 1.25)
        assert shell.state()["spacing"] == 20
        shell.set("layoutMode", "compact")
        assert shell.state()["spacing"] == 17
        shell.set("fontFamily", "DejaVu Sans")
        shell.set("fontScale", 1.5)
        assert shell.state()["font"] == "DejaVu Sans" and shell.state()["fontBody"] == 21
        for speed, duration in (("fast", 182), ("normal", 260), ("slow", 364)):
            shell.set("animationSpeed", speed)
            assert shell.state()["speed"] == speed and shell.state()["duration"] == duration
        shell.set("reducedMotion", True)
        assert shell.state()["duration"] == 0 and shell.state()["reduced"]
        shell.set("reducedMotion", False)
        shell.set("animationsEnabled", False)
        assert not shell.state()["motion"] and shell.state()["duration"] == 0
        print("PASS all appearance, typography, theme and motion settings react live", flush=True)

        for settings in (
            {"density": 0.8, "fontScale": 0.8, "cornerRadius": 0, "barPosition": "top", "layoutMode": "compact", "fontFamily": "DejaVu Sans"},
            {"density": 1.25, "fontScale": 1.5, "cornerRadius": 40, "barPosition": "bottom", "layoutMode": "comfortable", "fontFamily": "DejaVu Sans"},
            {"density": 0.8, "fontScale": 1.5, "cornerRadius": 18, "barPosition": "top", "layoutMode": "compact", "fontFamily": "DejaVu Sans Mono"},
        ) * 3:
            shell.update(settings)
            shell.run("panels")
            shell.run("bar")
        # Hiding each module, all modules, and restoring them must remove gaps
        # without losing layout bounds or the exclusive screen reservation.
        for name in defaults["modules"]:
            shell.set("modules", {name: False})
            shell.run("bar")
            shell.set("modules", {name: True})
        shell.set("modules", dict.fromkeys(defaults["modules"], False))
        shell.run("bar")
        shell.set("modules", defaults["modules"])
        shell.run("bar")
        shell.run("motion")
        print("PASS panel bounds, bar placement, hidden module layouts and interrupted motion", flush=True)

        notify("Before disable")
        eventually(lambda: shell.state()["history"] == 1 and shell.state()["toastVisible"])
        shell.set("notificationsEnabled", False)
        eventually(lambda: not shell.state()["toastVisible"])
        notify("Disabled")
        assert shell.state()["history"] == 1 and shell.state()["toasts"] == 0
        shell.set("notificationsEnabled", True)
        assert shell.state()["toasts"] == 0  # Old notifications must not replay.
        notify("Re-enabled")
        eventually(lambda: shell.state()["history"] == 2 and shell.state()["toastVisible"])
        shell.call("settingsTest", "showOsd")
        eventually(lambda: shell.state()["osdWindow"])
        shell.set("osdEnabled", False)
        eventually(lambda: not shell.state()["osdVisible"] and not shell.state()["osdWindow"])
        shell.call("settingsTest", "showOsd")
        assert not shell.state()["osdVisible"]
        shell.set("osdEnabled", True)
        assert not shell.state()["osdVisible"]
        shell.call("settingsTest", "showOsd")
        eventually(lambda: shell.state()["osdWindow"])
        print("PASS notification and OSD suppression, retained history, no stale replay", flush=True)

        for key, value in (("theme", "nope"), ("theme", "__proto__"), ("barPosition", "left"),
                           ("fontFamily", "\n"), ("fontScale", "large"), ("modules", {"clock": "false"}),
                           ("modules", {"unknown": False}), ("animationsEnabled", 0), ("unknown", 3),
                           ("animationSpeed", "warp"), ("layoutMode", "huge"), ("density", None)):
            before = shell.get()
            assert shell.settings("set", key, json.dumps(value)) == "invalid", key
            assert shell.get() == before
        before = shell.get()
        assert shell.settings("update", '{"theme":"amoled","osdEnabled":"false"}') == "invalid"
        assert shell.get() == before
        for patch, expected in (
            ({"transparency": -1, "blurStrength": -4, "cornerRadius": -1, "density": 0, "fontScale": 0},
             {"transparency": 0, "blurStrength": 0, "cornerRadius": 0, "density": 0.8, "fontScale": 0.8}),
            ({"transparency": 3, "blurStrength": 100, "cornerRadius": 100, "density": 10, "fontScale": 10},
             {"transparency": 1, "blurStrength": 16, "cornerRadius": 40, "density": 1.25, "fontScale": 1.5}),
        ):
            shell.update(patch)
            assert all(shell.get()[key] == value for key, value in expected.items())
        shell.set("modules", {"media": False, "systemStats": False})
        saved = shell.get()
        assert shell.settings("flush") == "saved"
        assert json.loads(state_path.read_text()) == dict(version=1, **saved)
        print("PASS strict validation, atomic rejection and numeric clamping", flush=True)

    with launch(temporary) as shell:
        assert shell.get() == saved
        assert shell.state()["theme"] == saved["theme"]
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "unavailable")
        with compositor(temporary):
            shell.set("blurStrength", 15)
            eventually(lambda: json.loads(shell.settings("status"))["blur"] == "applied")
            shell.set("blurStrength", saved["blurStrength"])
            assert shell.settings("flush") == "saved"
    print("PASS every setting persists across restart", flush=True)
    print("PASS unavailable compositor remains usable and recovers on the next update", flush=True)

    with launch(temporary, overrides={"VOID_THEME": "void-light", "VOID_MOTION": "off",
                "VOID_REDUCED_MOTION": "1", "VOID_MOTION_LEVEL": "fast"}) as shell:
        assert shell.get()["theme"] == "void-light" and shell.state()["duration"] == 0
        assert shell.state()["reduced"] and shell.state()["speed"] == "fast"
        shell.set("cornerRadius", 18)
        assert shell.settings("flush") == "saved"
        stored = json.loads(state_path.read_text())
        assert stored["theme"] == saved["theme"] and stored["animationSpeed"] == saved["animationSpeed"]
        shell.set("theme", "amoled")
        assert shell.state()["theme"] == "amoled"
    print("PASS session environment compatibility and explicit runtime overrides", flush=True)

    for invalid in ("{malformed", "null", "[]", '{"version":99}',
                    '{"fontScale":"bad","notificationsEnabled":"false","theme":"absent"}'):
        state_path.write_text(invalid)
        with launch(temporary) as shell:
            assert shell.get() == defaults, (invalid, shell.get())
            assert shell.settings("flush") == "saved"
            assert json.loads(state_path.read_text()) == dict(version=1, **defaults)
    state_path.write_text('{"cornerRadius":999,"fontScale":-1,"modules":{"clock":false,"media":"false","typo":true}}')
    with launch(temporary) as shell:
        assert shell.get()["cornerRadius"] == 40 and shell.get()["fontScale"] == 0.8
        assert not shell.get()["modules"]["clock"] and shell.get()["modules"]["media"]
    print("PASS malformed, wrong-shaped and invalid persisted settings repair safely", flush=True)

    # Use the real XDG-derived location, then place the Phase 10 file alongside it.
    with launch(temporary, default_path=True) as shell:
        xdg_path = pathlib.Path(shell.settings("path"))
        assert xdg_path.is_relative_to(temporary / "state")
        eventually(lambda: xdg_path.is_file())
        assert json.loads(xdg_path.read_text()) == dict(version=1, **defaults)
    xdg_path.unlink()
    legacy = xdg_path.with_name("theme.json")
    legacy.write_text('{"version":1,"theme":"warm-glass"}')
    with launch(temporary, default_path=True) as shell:
        assert shell.get()["theme"] == "warm-glass"
        assert shell.settings("flush") == "saved"
        assert json.loads(xdg_path.read_text())["theme"] == "warm-glass"
    assert legacy.read_text() == '{"version":1,"theme":"warm-glass"}'
    with launch(temporary, default_path=True) as shell:
        shell.set("theme", "amoled")
        assert shell.settings("flush") == "saved"
    with launch(temporary, default_path=True) as shell:
        assert shell.get()["theme"] == "amoled"  # Migration happens only once.
    print("PASS XDG paths, Phase 10 migration and single settings-file ownership", flush=True)

    # Start the actual entrypoint without changing the desktop's global blur.
    state_path.write_text('{"version":1,"blurStrength":0}')
    with launch(temporary, config=ROOT / "shell/shell.qml") as shell:
        assert shell.get()["blurStrength"] == 0
        eventually(lambda: json.loads(shell.settings("status"))["blur"] == "off")
        assert shell.call("theme", "current") == "void-dark"
        shell.set("barPosition", "bottom")
        shell.set("theme", "void-light")
        assert shell.call("theme", "current") == "void-light"
        assert shell.settings("flush") == "saved"
    print("PASS real Quickshell startup and runtime IPC", flush=True)
