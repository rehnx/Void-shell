# VoidShell

RehanShell is a small Arch Linux shell built on Hyprland, Quickshell, and QML.
Phase 3 adds a native application launcher to the existing compositor and top
panel foundation. Press `Super+R` to open it, type to search, use the arrow keys
to select an application, and press Enter to launch it.

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
