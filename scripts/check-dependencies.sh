#!/usr/bin/env bash
set -u

dependencies=(Hyprland qs swaybg kitty)
missing=()

for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        missing+=("$dependency")
    fi
done

if ((${#missing[@]})); then
    printf 'Missing dependencies:\n'
    printf '  %s\n' "${missing[@]}"
    printf '\nInstall the corresponding Arch packages, then run this check again.\n'
    exit 1
fi

printf 'All required dependencies are available.\n'
