"""Validate runtime themes, persistence, dynamic extraction and fallbacks."""
import json
import os
import pathlib
import subprocess
import tempfile
import time


ROOT = pathlib.Path(__file__).resolve().parents[2]
CONFIG = ROOT / "shell" / "theme-test.qml"


def color(value):
    raw = value.lstrip("#")
    if len(raw) == 8:
        raw = raw[2:]
    return tuple(int(raw[index:index + 2], 16) / 255 for index in (0, 2, 4))


def luminance(rgb):
    def channel(value):
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
    red, green, blue = map(channel, rgb)
    return red * 0.2126 + green * 0.7152 + blue * 0.0722


def contrast(first, second):
    bright, dark = sorted((luminance(color(first)), luminance(color(second))), reverse=True)
    return (bright + 0.05) / (dark + 0.05)


def make_wallpaper(path):
    width, height = 48, 32
    pixels = bytearray()
    for y in range(height):
        for x in range(width):
            if x < width // 2:
                pixels.extend((25, 52 + y, 105 + x))
            else:
                pixels.extend((215, 80 + y, 42))
    path.write_bytes(f"P6\n{width} {height}\n255\n".encode() + pixels)


def launch(state_path, wallpaper=""):
    environment = os.environ.copy()
    environment["VOID_THEME_STATE"] = str(state_path)
    if wallpaper:
        environment["VOID_WALLPAPER"] = wallpaper
    return subprocess.Popen(["qs", "-p", str(CONFIG)], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, env=environment)


def call(process, method, *args):
    return subprocess.check_output(
        ["qs", "ipc", "--pid", str(process.pid), "call", "theme", method, *map(str, args)],
        text=True, stderr=subprocess.STDOUT, timeout=8).strip()


def eventually(process, method, expected, timeout=8):
    deadline = time.monotonic() + timeout
    value = "unavailable"
    while time.monotonic() < deadline:
        try:
            value = call(process, method)
            if value == expected:
                return value
        except subprocess.SubprocessError:
            if process.poll() is not None:
                break
        time.sleep(0.05)
    raise AssertionError(f"{method} did not become {expected!r}; last value was {value!r}")


def stop(process):
    process.terminate()
    process.wait(timeout=5)
    output = process.stdout.read()
    problems = [line for line in output.splitlines()
                if "ERROR" in line or "TypeError" in line or "WARN scene" in line]
    if problems:
        raise AssertionError("Theme runtime errors:\n" + "\n".join(problems))


with tempfile.TemporaryDirectory() as directory:
    temporary = pathlib.Path(directory)
    state_path = temporary / "theme.json"
    wallpaper = temporary / "palette sample #1.ppm"
    invalid_wallpaper = temporary / "invalid.png"
    make_wallpaper(wallpaper)
    invalid_wallpaper.write_text("not an image")

    process = launch(state_path)
    eventually(process, "ready", "ready")
    assert call(process, "list").split(",") == [
        "void-dark", "void-light", "amoled", "warm-glass", "dynamic"
    ]
    snapshots = {}
    for theme in ("void-dark", "void-light", "amoled", "warm-glass"):
        assert call(process, "setTheme", theme) == theme
        snapshot = json.loads(call(process, "snapshot"))
        snapshots[theme] = snapshot
        assert snapshot["id"] == theme
        assert contrast(snapshot["textPrimary"], snapshot["background"]) >= 7
        assert contrast(snapshot["textSecondary"], snapshot["background"]) >= 4.5
        assert contrast(snapshot["textOnAccent"], snapshot["accent"]) >= 4.5
    assert len({entry["surface"] for entry in snapshots.values()}) == 4
    assert len({entry["accent"] for entry in snapshots.values()}) == 4
    print("PASS all built-in themes switch live with safe contrast")

    assert call(process, "setWallpaper", wallpaper) == "loading"
    assert call(process, "setTheme", "dynamic") == "dynamic"
    try:
        eventually(process, "status", "ready")
    except AssertionError:
        process.terminate()
        process.wait(timeout=5)
        print(process.stdout.read())
        raise
    dynamic = json.loads(call(process, "snapshot"))
    assert dynamic["accent"] not in {entry["accent"] for entry in snapshots.values()}
    assert contrast(dynamic["textPrimary"], dynamic["background"]) >= 7
    assert contrast(dynamic["textOnAccent"], dynamic["accent"]) >= 4.5
    print("PASS wallpaper palette extraction and dynamic contrast")

    assert call(process, "setWallpaper", temporary / "missing.png") == "loading"
    eventually(process, "status", "fallback")
    fallback = json.loads(call(process, "snapshot"))
    assert fallback["id"] == "dynamic" and fallback["accent"]
    print("PASS missing wallpaper uses a safe palette")

    assert call(process, "setWallpaper", invalid_wallpaper) == "loading"
    eventually(process, "status", "fallback")
    assert json.loads(call(process, "snapshot"))["accent"]
    print("PASS invalid wallpaper uses a safe palette")

    assert call(process, "setTheme", "warm-glass") == "warm-glass"
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        try:
            if json.loads(state_path.read_text())["theme"] == "warm-glass":
                break
        except (OSError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    else:
        raise AssertionError("Theme selection was not persisted")
    stop(process)

    process = launch(state_path)
    eventually(process, "ready", "ready")
    assert call(process, "current") == "warm-glass"
    stop(process)
    print("PASS persisted theme restores after restart")

    state_path.write_text("{malformed")
    process = launch(state_path)
    eventually(process, "ready", "ready")
    assert call(process, "current") == "void-dark"
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        try:
            if json.loads(state_path.read_text())["theme"] == "void-dark":
                break
        except (OSError, json.JSONDecodeError):
            pass
        time.sleep(0.05)
    else:
        raise AssertionError("Malformed state was not repaired")
    stop(process)
    print("PASS malformed state falls back and repairs safely")
