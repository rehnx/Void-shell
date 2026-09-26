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
