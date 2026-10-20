#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

command -v stow >/dev/null || { echo "stow is not installed: sudo pacman -S stow" >&2; exit 1; }

git config core.hooksPath .githooks

mapfile -t packages < <(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' ! -name graphify-out -printf '%f\n' | sort)

stow --no "${packages[@]}" >/dev/null
stow "${packages[@]}"

echo "Stowed: ${packages[*]}"

if [[ ! -f "$HOME/.config/hypr/colors.lua" ]] && command -v matugen >/dev/null; then
    matugen color hex "#b86b4f" -m dark -t scheme-tonal-spot >/dev/null
    echo "Seeded default colors (run: wallpaper --pick)"
fi

# Klee One isn't packaged: pinned commit + checksums
fonts=${XDG_DATA_HOME:-$HOME/.local/share}/fonts/KleeOne
if [[ ! -f $fonts/KleeOne-Regular.ttf ]]; then
    mkdir -p "$fonts"
    rev=130fcfb0ff422fec96b335616b2ca99f91914792
    for f in KleeOne-Regular KleeOne-SemiBold; do
        curl -fsSL -o "$fonts/$f.ttf" "https://raw.githubusercontent.com/google/fonts/$rev/ofl/kleeone/$f.ttf"
    done
    (cd "$fonts" && sha256sum -c --quiet <<'SUMS'
bf4063f030cc2ae6adf0a11424a1888e5c0eb4438f1f6d02f52294af868e9b3a  KleeOne-Regular.ttf
b031ec426c23ca1143ef1f7d58bee7a79efe119ed654152f121c922202b303fd  KleeOne-SemiBold.ttf
SUMS
    ) || { rm -rf "$fonts"; echo "Klee One download failed its checksum" >&2; exit 1; }
    fc-cache -f "$fonts" >/dev/null
    echo "Installed Klee One"
fi

if command -v gsettings >/dev/null; then
    s=org.gnome.desktop.interface
    gsettings set $s cursor-theme capitaine-cursors # keep in sync with XCURSOR_THEME in uwsm/env
    gsettings set $s cursor-size 24
    gsettings set $s font-name 'Nunito 11'
    gsettings set $s document-font-name 'Nunito 11'
    gsettings set $s monospace-font-name '0xProto Nerd Font 11'
fi

if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme Matugen
fi

services=(awww-daemon quickshell hyprpolkitagent cliphist hypridle)
systemctl --user daemon-reload
systemctl --user enable --now "${services[@]/%/.service}" ||
    echo "Could not start all services; inside a Hyprland session run: systemctl --user enable --now ${services[*]}" >&2
