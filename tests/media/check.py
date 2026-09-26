"""Run with dbus-run-session -- python3 tests/media/check.py."""
import json
import pathlib
import subprocess
import tempfile
import time


ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "shell" / "media-test.qml"
FIXTURE = pathlib.Path(__file__).with_name("mock_player.py")


def call(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=5).strip()


def ipc(method, *args):
    return call("qs", "ipc", "--pid", str(shell.pid), "call", "mediaTest", method, *map(str, args))


def state():
    return json.loads(ipc("state"))


def eventually(predicate, timeout=5):
    until = time.monotonic() + timeout
    while time.monotonic() < until:
        try:
            if predicate():
                return
        except (subprocess.SubprocessError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    raise AssertionError("Media state did not reach expected value: " + str(state()))


def fixture(name, method, *args):
    return call("gdbus", "call", "--session", "--dest", name,
                "--object-path", "/org/mpris/MediaPlayer2", "--method",
                "org.void.MediaTest." + method, "--", *map(str, args))


def start_player(name, identity, limited=False):
    return subprocess.Popen(["python3", str(FIXTURE), name, identity]
                            + (["limited"] if limited else []),
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def stop(process):
    process.terminate()
    process.wait(timeout=5)


spotify_name = "org.mpris.MediaPlayer2.VoidSpotify"
browser_name = "org.mpris.MediaPlayer2.VoidBrowser"
with tempfile.TemporaryFile(mode="w+") as log:
    shell = subprocess.Popen(["qs", "-p", str(CONFIG)], stdout=log, stderr=log)
    spotify = None
    browser = None
    try:
        eventually(lambda: state()["count"] == 0)
        assert state()["title"] == "Nothing playing"
        assert ipc("interactions") == "passed"
        print("PASS no-player state, panel opening, Escape and outside click")

        spotify = start_player(spotify_name, "Spotify")
        eventually(lambda: state()["selected"] == "Spotify")
        info = state()
        assert info["title"] == "First Song" and info["artist"] == "Example Artist"
        assert info["album"] == "Example Album" and info["artwork"] == ""
        assert info["playing"] and info["seek"] and info["volumeSupported"]
        assert info["length"] == 120 and abs(info["position"] - 20) < 1
        print("PASS Spotify-style detection, metadata, missing artwork, progress")

        browser = start_player(browser_name, "Browser", limited=True)
        eventually(lambda: state()["count"] == 2)
        assert state()["selected"] == "Spotify"
        ipc("choose", state()["names"].index("Browser"))
        eventually(lambda: state()["selected"] == "Browser")
        assert not state()["seek"] and not state()["volumeSupported"]
        assert not state()["previous"] and not state()["next"]
        ipc("next")
        ipc("seek", 45)
        ipc("volume", 0.3)
        assert "next" not in fixture(browser_name, "GetCalls")
        print("PASS multiple players, browser-style limited capabilities")

        ipc("choose", state()["names"].index("Spotify"))
        ipc("toggle")
        eventually(lambda: not state()["playing"])
        ipc("toggle")
        eventually(lambda: state()["playing"])
        ipc("next")
        eventually(lambda: state()["title"] == "Next Song")
        ipc("previous")
        eventually(lambda: state()["title"] == "Previous Song")
        assert "pause" in fixture(spotify_name, "GetCalls")
        assert "play" in fixture(spotify_name, "GetCalls")
        print("PASS play/pause, previous/next, metadata changes")

        artwork = "file:///usr/share/icons/hicolor/24x24/apps/spotify.png"
        fixture(spotify_name, "SetMetadata", "New title", "New artist", "New album", artwork)
        eventually(lambda: state()["title"] == "New title")
        info = state()
        assert (info["artist"], info["album"], info["artwork"]) == ("New artist", "New album", artwork)
        eventually(lambda: ipc("artworkReady") == "true")
        ipc("seek", 45)
        eventually(lambda: abs(state()["position"] - 45) < 1)
        ipc("volume", 0.35)
        eventually(lambda: abs(state()["volume"] - 0.35) < 0.01)
        assert "setPosition" in fixture(spotify_name, "GetCalls")
        assert "volume" in fixture(spotify_name, "GetCalls")
        print("PASS artwork display, seek, media volume")

        stop(spotify)
        spotify = None
        eventually(lambda: state()["count"] == 1 and state()["selected"] == "Browser")
        stop(browser)
        browser = None
        eventually(lambda: state()["count"] == 0 and state()["title"] == "Nothing playing")
        browser = start_player(browser_name, "Browser", limited=True)
        eventually(lambda: state()["selected"] == "Browser")
        print("PASS player close, fallback and reopen")
    finally:
        if spotify is not None:
            stop(spotify)
        if browser is not None:
            stop(browser)
        shell.terminate()
        shell.wait(timeout=5)
        log.seek(0)
        output = log.read()
        if "ERROR" in output or "WARN scene" in output:
            print(output)
            raise AssertionError("Quickshell runtime error")
