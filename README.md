# VoidShell

RehanShell is a small Arch Linux shell built on Hyprland, Quickshell, and QML.
Phase 3 adds a native application launcher to the existing compositor and top
panel foundation. Press `Super+R` to open it, type to search, use the arrow keys
to select an application, and press Enter to launch it.

Phase 4 adds the floating Control Center: click the rightmost bar button or
press `Super+C`. Escape or a click outside closes it. Wi-Fi and Bluetooth
toggles use the system services; volume uses PipeWire. Battery status appears
when available. Brightness requires the optional `brightnessctl` package and
permission to change the backlight; its value refreshes when the panel opens
and after adjustments. Missing hardware or services leave controls disabled.

Phase 5 adds notifications through Quickshell's native notification server.
Open history using the bar's Notifications button or `Super+N`; Escape or a
click outside closes it. Toasts and history share dismiss controls, and history
has a Clear all button. App, title, plain-text body, icon, and receipt time are
shown. Normal toasts expire after six seconds unless the sender supplies a
timeout; critical notifications and timeout-zero notifications remain until
dismissed. Up to three toasts are shown at once. History keeps the newest 100
entries in memory, including expired notifications, until cleared or restarted.
Transient notifications skip history. No history is written to disk.

Only one notification daemon can own `org.freedesktop.Notifications` on the
session bus. For normal use, disable any other notification daemon in your own
session configuration; the installer does not stop existing services. Without
session D-Bus, the history panel remains usable but cannot receive notifications.

Notification integration checks (requires Python, `gdbus`, Qt Quick Test, and a
running Wayland session) use a private bus without replacing the desktop daemon:

```sh
dbus-run-session -- python3 tests/notifications/check.py
dbus-run-session -- python3 tests/notifications/check.py --unavailable
```

Phase 6 adds a compact media widget to the bar and a floating panel opened by
the widget or `Super+M`. The panel shows MPRIS title, artist, album, artwork,
progress, player volume, and available playback controls. If several players
are present, it prefers a playing one until a player is selected in the panel.
Unsupported controls stay disabled and missing metadata or artwork has a safe
placeholder. Progress refreshes only while the panel is open and playing.

The MPRIS integration check runs two mock players on a private D-Bus session:

```sh
dbus-run-session -- python3 tests/media/check.py
```

Phase 7 adds a confirmation-based power menu, volume/brightness/microphone OSD,
a navigable local calendar, and lightweight CPU, RAM, temperature, and battery
status. Open the calendar with `Super+D` and the power menu with `Super+P`.
Hardware media keys display the OSD. Temperature, battery, and brightness stay
hidden or unavailable when the corresponding hardware or service is absent.
Brightness control uses the optional `brightnessctl` package.

The core utility integration check disables execution of all power commands:

```sh
dbus-run-session -- python3 tests/core/check.py
```

Phase 8 centralizes surface and interaction motion in `shell/components/Motion.qml`.
Set `VOID_MOTION_LEVEL=fast|normal|slow` before starting Quickshell to select
timing, `VOID_REDUCED_MOTION=1` for immediate transitions without transforms,
or `VOID_MOTION=off` to disable motion. The singleton exposes the same writable
settings for future configuration integration; no settings UI is added.

`FloatingSurface` combines the existing glass with fade, scale, slide and
elevation. Bind the containing window's visibility to its `present` property
and its input/focus to the logical open state. `AnimatedVisibility` provides
the same lifecycle for other content. `InteractionMotion` supplies shared
hover, press/release, focus, selected and disabled feedback without owning input.
All transitions settle and stop; no motion timers or animated blur are used.

`ContextualSurface` interpolates compact/expanded rectangles in one parent
coordinate space. Use it for locally owned popup/card geometry; do not put
its animated geometry under a Layout or force morphs between separate windows.
`FloatingSurface.animateGeometry` is opt-in (used for power confirmation sizing).

Motion regression checks exercise actual panels, interrupted transitions,
input feedback, toast lifetime, contextual geometry and configuration modes:

```sh
dbus-run-session -- python3 tests/motion/check.py
```

## Dependencies

Install these Arch packages (an AUR helper may be needed for Quickshell):

- `hyprland`
- `quickshell`
- `swaybg`
- `kitty`

## Install

```sh
./scripts/check-dependencies.sh
./install.sh
```

The installer honors `XDG_CONFIG_HOME` and `XDG_STATE_HOME`, defaulting to
`~/.config` and `~/.local/state`. Managed files are installed under
`$XDG_CONFIG_HOME/hypr` and `$XDG_CONFIG_HOME/rehanshell/shell`.

Changed destination files are backed up below
`$XDG_STATE_HOME/rehanshell/backups` before replacement. Re-running the
installer leaves identical files alone. Existing `hypr/user.conf` is always
preserved; put monitor, input, and other machine-specific overrides there.

Start Hyprland normally. It starts the solid-color wallpaper and the
`rehanshell` Quickshell configuration once per session.
# Void-shell
# Void-shell
