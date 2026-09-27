#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
state_home=${XDG_STATE_HOME:-"$HOME/.local/state"}
hypr_dir="$config_home/hypr"
shell_dir="$config_home/rehanshell/shell"
component_dir="$shell_dir/components"
backup_dir="$state_home/rehanshell/backups/$(date +%Y%m%d-%H%M%S-%N)"
backup_created=false

backup_file() {
    local destination=$1
    local relative_path=${destination#"$config_home"/}

    if [[ -e $destination || -L $destination ]]; then
        mkdir -p -- "$backup_dir/$(dirname -- "$relative_path")"
        cp -a -- "$destination" "$backup_dir/$relative_path"
        backup_created=true
    fi
}

install_managed_file() {
    local source=$1
    local destination=$2

    if [[ -f $destination ]] && cmp -s -- "$source" "$destination"; then
        return
    fi

    backup_file "$destination"
    install -Dm644 -- "$source" "$destination"
    printf 'Installed %s\n' "$destination"
}

mkdir -p -- "$hypr_dir" "$component_dir"

install_managed_file "$project_dir/hypr/hyprland.conf" "$hypr_dir/hyprland.conf"
install_managed_file "$project_dir/hypr/keybinds.conf" "$hypr_dir/keybinds.conf"
install_managed_file "$project_dir/hypr/autostart.conf" "$hypr_dir/autostart.conf"
install_managed_file "$project_dir/shell/shell.qml" "$shell_dir/shell.qml"
install_managed_file "$project_dir/shell/Bar.qml" "$shell_dir/Bar.qml"
install_managed_file "$project_dir/shell/Launcher.qml" "$shell_dir/Launcher.qml"
install_managed_file "$project_dir/shell/ControlCenter.qml" "$shell_dir/ControlCenter.qml"
for component in ControlStyle GlassSurface ControlIcon QuickToggle ControlSlider BrightnessControl ShellButton NotificationCard MediaArtwork MediaControls OSD; do
    install_managed_file "$project_dir/shell/components/$component.qml" "$component_dir/$component.qml"
done
install_managed_file "$project_dir/shell/services/NotificationService.qml" "$shell_dir/services/NotificationService.qml"
install_managed_file "$project_dir/shell/services/MediaService.qml" "$shell_dir/services/MediaService.qml"
install_managed_file "$project_dir/shell/services/SystemService.qml" "$shell_dir/services/SystemService.qml"
install_managed_file "$project_dir/shell/widgets/MediaWidget.qml" "$shell_dir/widgets/MediaWidget.qml"
install_managed_file "$project_dir/shell/widgets/Calendar.qml" "$shell_dir/widgets/Calendar.qml"
install_managed_file "$project_dir/shell/widgets/SystemStats.qml" "$shell_dir/widgets/SystemStats.qml"
for panel in NotificationCenter NotificationToasts MediaPanel CalendarPanel PowerMenu; do
    install_managed_file "$project_dir/shell/panels/$panel.qml" "$shell_dir/panels/$panel.qml"
done
install_managed_file "$project_dir/shell/components/AppItem.qml" "$component_dir/AppItem.qml"
install_managed_file "$project_dir/shell/components/Workspaces.qml" "$component_dir/Workspaces.qml"
install_managed_file "$project_dir/shell/components/ActiveWindow.qml" "$component_dir/ActiveWindow.qml"
install_managed_file "$project_dir/shell/components/Clock.qml" "$component_dir/Clock.qml"
install_managed_file "$project_dir/shell/components/WifiStatus.qml" "$component_dir/WifiStatus.qml"
install_managed_file "$project_dir/shell/components/VolumeStatus.qml" "$component_dir/VolumeStatus.qml"
install_managed_file "$project_dir/shell/components/BatteryStatus.qml" "$component_dir/BatteryStatus.qml"
install_managed_file "$project_dir/shell/components/Tray.qml" "$component_dir/Tray.qml"

if [[ ! -e $hypr_dir/user.conf && ! -L $hypr_dir/user.conf ]]; then
    install -Dm644 -- "$project_dir/hypr/user.conf" "$hypr_dir/user.conf"
    printf 'Created %s\n' "$hypr_dir/user.conf"
else
    printf 'Preserved user overrides at %s\n' "$hypr_dir/user.conf"
fi

if [[ $backup_created == true ]]; then
    printf 'Backed up replaced files to %s\n' "$backup_dir"
fi

printf 'RehanShell Phase 7 installation complete.\n'
