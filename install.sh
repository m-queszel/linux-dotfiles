#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

command -v stow >/dev/null || { echo "stow is not installed: sudo pacman -S stow" >&2; exit 1; }

git config core.hooksPath .githooks

./link
echo "Linked: $(find . -mindepth 1 -maxdepth 1 -type d ! -name '.*' ! -name graphify-out -printf '%f ')"

if [[ ! -f "$HOME/.config/hypr/colors.lua" ]] && command -v matugen >/dev/null; then
    matugen color hex "#b86b4f" -m dark -t scheme-tonal-spot >/dev/null
    bin/theme-reload dark
    echo "Seeded default colors (run: wallpaper --pick)"
fi

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
    gsettings set $s cursor-theme capitaine-cursors
    gsettings set $s cursor-size 24
    gsettings set $s font-name 'Nunito 11'
    gsettings set $s document-font-name 'Nunito 11'
    gsettings set $s monospace-font-name '0xProto Nerd Font 11'
fi

if command -v xfconf-query >/dev/null; then
    thunar_set() { xfconf-query -c thunar -p "/$1" -n -t "$2" -s "$3"; }
    thunar_set last-view string ThunarDetailsView
    thunar_set last-details-view-zoom-level string THUNAR_ZOOM_LEVEL_38_PERCENT
    thunar_set last-details-view-column-order string THUNAR_COLUMN_PERMISSIONS,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_NAME,THUNAR_COLUMN_TYPE,THUNAR_COLUMN_OWNER,THUNAR_COLUMN_GROUP,THUNAR_COLUMN_MIME_TYPE,THUNAR_COLUMN_SIZE_IN_BYTES,THUNAR_COLUMN_DATE_ACCESSED,THUNAR_COLUMN_DATE_CREATED,THUNAR_COLUMN_LOCATION,THUNAR_COLUMN_DATE_DELETED,THUNAR_COLUMN_RECENCY
    thunar_set last-details-view-visible-columns string THUNAR_COLUMN_PERMISSIONS,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_DATE_MODIFIED,THUNAR_COLUMN_NAME
    thunar_set last-location-bar string ThunarLocationButtons
    thunar_set last-menubar-visible bool false
    thunar_set last-statusbar-visible bool true
    thunar_set misc-thumbnail-mode string THUNAR_THUMBNAIL_MODE_NEVER
    thunar_set misc-date-style string THUNAR_DATE_STYLE_CUSTOM
    thunar_set misc-date-custom-style string '%b %d %H:%M'
    thunar_set misc-folder-item-count string THUNAR_FOLDER_ITEM_COUNT_ALWAYS
    thunar_set misc-file_size_binary bool true
    thunar_set misc-small-toolbar-icons bool true
    thunar_set misc-use-csd bool false
    thunar_set misc-highlighting-enabled bool false
    thunar_set misc-window-title-style string THUNAR_WINDOW_TITLE_STYLE_FULL_PATH_WITHOUT_THUNAR_SUFFIX
    thunar_set shortcuts-icon-size string THUNAR_ICON_SIZE_24
    thunar_set tree-icon-size string THUNAR_ICON_SIZE_24
    xfconf-query -c thunar -p /hidden-bookmarks -n -a -t string -s recent:/// -t string -s network:///
fi

accels=${XDG_CONFIG_HOME:-$HOME/.config}/Thunar/accels.scm
f4='(gtk_accel_path "<Actions>/ThunarActions/uca-action-kitty-here" "F4")'
grep -qxF "$f4" "$accels" 2>/dev/null || echo "$f4" >>"$accels"

xdg-mime default thunar.desktop inode/directory

services=(awww-daemon quickshell hyprpolkitagent cliphist hypridle)
systemctl --user daemon-reload
systemctl --user enable --now "${services[@]/%/.service}" ||
    echo "Could not start all services; inside a Hyprland session run: systemctl --user enable --now ${services[*]}" >&2
