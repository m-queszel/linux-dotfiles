#!/usr/bin/env bash
# Bootstrap: enable repo git hooks, stow every package into $HOME, seed colors, enable services.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

command -v stow >/dev/null || { echo "stow is not installed: sudo pacman -S stow" >&2; exit 1; }

git config core.hooksPath .githooks

# Every non-hidden top-level directory is a stow package.
mapfile -t packages < <(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' | sort)

stow --no "${packages[@]}" >/dev/null # dry run first: abort before touching anything on conflict
stow "${packages[@]}"

echo "Stowed: ${packages[*]}"

# Generated color files aren't tracked; seed a default palette until the first `wallpaper` run.
if [[ ! -f "$HOME/.config/hypr/colors.lua" ]] && command -v matugen >/dev/null; then
    matugen color hex "#b86b4f" -m dark -t scheme-tonal-spot >/dev/null
    echo "Seeded default colors (run: wallpaper --pick)"
fi

# GTK settings live in dconf, not files. Light/dark, theme and icons are set by `wallpaper`.
if command -v gsettings >/dev/null; then
    s=org.gnome.desktop.interface
    gsettings set $s cursor-theme capitaine-cursors # keep in sync with XCURSOR_THEME in uwsm/env
    gsettings set $s cursor-size 24
    gsettings set $s font-name 'Nunito 11'
    gsettings set $s document-font-name 'Nunito 11'
    gsettings set $s monospace-font-name '0xProto Nerd Font 11'
fi

# KDE apps ignore the qt6ct palette and use their own color scheme: point them at matugen's.
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme Matugen
fi

services=(awww-daemon quickshell hyprpolkitagent cliphist hypridle)
systemctl --user daemon-reload
systemctl --user enable --now "${services[@]/%/.service}" ||
    echo "Could not start all services; inside a Hyprland session run: systemctl --user enable --now ${services[*]}" >&2
