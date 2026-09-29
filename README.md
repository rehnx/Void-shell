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

Phase 9 adds the static premium visual system in `shell/components/Theme.qml`.
It owns semantic colors, type sizes/weights, spacing, radii, border/shadow
levels, opacity and common dimensions. `ControlStyle` remains a compatibility
facade; components share the same tokens. The palette uses dark slate glass,
cool blue accents and restrained borders, with separate panel and card layers.

`PanelSurface`, `PopupSurface` and `CardSurface` build on the Phase 8
surfaces. `ShellText` supports display/title/body/label/caption roles;
`SectionHeader`, `Separator`, `ShellSlider`, `ShellComboBox` and
`PanelScrollArea` standardize recurring visuals and bounded content.
Shadows use static geometry. Compositor blur remains limited to the bar,
launcher and Control Center, guarded by `Theme.blurEnabled`; shadows are
guarded by `Theme.shadowsEnabled`. No theme switching or customization UI
is included. Semantic palette inputs are centralized for future providers.

Run the existing core/media/notification/motion checks after visual changes.
The design stress check uses safe fixtures for long and missing text/data:

```sh
dbus-run-session -- python3 tests/motion/check.py design
```

Set `VOID_MOTION_CAPTURE_DIR` to an existing writable directory when running
the motion checker to capture all major panels for visual review.

Phase 10 adds runtime palettes through `shell/theme/ThemeManager.qml` while
keeping the Phase 9 `Theme` singleton as the only token source used by UI
components. Built-in IDs are `void-dark`, `void-light`, `amoled`, and
`warm-glass`; `dynamic` derives a guarded dark palette from a wallpaper using
Quickshell's asynchronous color quantizer. Set `VOID_WALLPAPER` to an image
path, or let the manager make one startup-time attempt to detect hyprpaper,
swww, or swaybg. Missing and invalid images retain a readable fallback.

The selected theme is stored atomically in Quickshell's state directory and is
restored at startup. Runtime control is available without restarting the shell:

```sh
qs ipc call theme list
qs ipc call theme setTheme void-light
qs ipc call theme setWallpaper /absolute/path/to/wallpaper.png
qs ipc call theme setTheme dynamic
```

`VOID_THEME` overrides the restored selection for a session. Theme extraction
runs only when dynamic mode is selected or explicitly refreshed. Validate the
engine with `dbus-run-session -- python3 tests/theme/check.py`.

Phase 11 adds one reactive customization owner in
`shell/services/Settings.qml`. ThemeManager, Motion and the existing visual
tokens consume it, so changes reach the bar, launcher, panels, calendar and
OSD without restarting Quickshell. No settings GUI is included.

| Setting | Values | Default |
| --- | --- | --- |
| `theme` | Existing built-in IDs and `dynamic` | `void-dark` |
| `transparency` | 0–1; opaque to the palette's original glass transparency | 1 |
| `blurStrength` | Integer 0–16; 0 disables shell blur requests | 8 |
| `cornerRadius` | Integer 0–40 pixels; smaller radii scale with it | 28 |
| `density` | 0.8–1.25 spacing scale | 1 |
| `animationSpeed` | `fast`, `normal`, `slow` | `normal` |
| `reducedMotion` | Boolean | `false` |
| `barPosition` | `top`, `bottom` | `top` |
| `modules` | Object mapping module names to booleans | All visible |
| `layoutMode` | `compact`, `comfortable` | `comfortable` |
| `fontFamily` | Nonempty font family, up to 128 characters | `Sans Serif` |
| `fontScale` | 0.8–1.5 | 1 |
| `animationsEnabled` | Boolean | `true` |
| `notificationsEnabled` | Boolean | `true` |
| `osdEnabled` | Boolean | `true` |

Module names are `workspaces`, `activeWindow`, `media`, `systemStats`, `tray`,
`wifi`, `volume`, `clock`, `calendar`, `notifications`, `power` and
`controlCenter`. Hiding a module removes its bar space; panel keyboard
shortcuts remain available. Bottom placement also moves the adjacent panels
and toasts and keeps the OSD above the bar. Disabling notifications hides
current toasts and ignores new notifications while retaining existing history.
Re-enabling notifications or OSD does not replay suppressed content.

Use the internal IPC interface; values and patches are JSON:

```sh
qs ipc call settings get
qs ipc call settings set fontScale 1.15
qs ipc call settings set barPosition '"bottom"'
qs ipc call settings update '{"theme":"warm-glass","modules":{"media":false}}'
qs ipc call settings status
qs ipc call settings path
qs ipc call settings flush
qs ipc call settings reset
```

QML consumers use `Settings.setValue(key, value)` or `Settings.update(patch)`.
Numbers are clamped to their supported ranges; invalid types, unknown keys
and unsupported choices reject the entire patch. Missing or malformed files
recover to defaults, and valid fields in partially invalid files are retained.
Writes are atomic and coalesced for 80 ms; `flush` waits for pending persistence.
The versioned document is `settings.json` in Quickshell's XDG state directory
(`$XDG_STATE_HOME`, or `~/.local/state`). On first use, the old `theme.json`
is migrated without modifying it. `VOID_SETTINGS_PATH` selects an alternate
file; the existing `VOID_THEME_STATE` override remains supported.

`VOID_THEME`, `VOID_MOTION_LEVEL`, `VOID_MOTION` and `VOID_REDUCED_MOTION`
remain session overrides and are not saved merely by starting the shell.
An explicit runtime change to the corresponding setting replaces that override.
Positive blur strength uses Hyprland's compositor-wide `decoration:blur:size`
option, affecting other blurred windows too; palettes such as AMOLED still
disable shell blur. Unavailable compositor IPC leaves the shell usable and
is reported by `settings status`.

The customization integration check uses temporary settings and a fake
compositor socket, with power commands disabled:

```sh
dbus-run-session -- python3 tests/settings/check.py
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
