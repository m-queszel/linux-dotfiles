# linux-dotfiles

A cozy, soft Arch Linux + Hyprland rice. Every color comes from the wallpaper.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

| | |
|---|---|
| Compositor | Hyprland 0.56 (Lua config), uwsm session |
| Shell UI | Quickshell: auto-hiding bar, notifications |
| Launcher | rofi 2.0 |
| Terminal | kitty, zsh, starship, animated pixel prompt |
| Theming | matugen from the wallpaper (awww): Hyprland, apps, GTK, Qt, lock screen |
| Lock / idle | hyprlock, hypridle (lock 15 min, screen off 16 min) |

## Install

```bash
sudo pacman -S --needed git stow hyprland uwsm kitty rofi quickshell awww matugen \
  imagemagick hyprlock hypridle hyprpolkitagent cliphist wl-clipboard libnotify \
  zsh zsh-autosuggestions zsh-syntax-highlighting starship python \
  ttf-nunito ttf-0xproto-nerd papirus-icon-theme capitaine-cursors \
  adw-gtk-theme qt6ct xdg-desktop-portal-gtk wireplumber playerctl
git clone git@github.com:m-queszel/linux-dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh   # stow, seed colors, enable user services
chsh -s /usr/bin/zsh            # then log out and back in
```

Then pick a wallpaper: put images in `~/Pictures/Wallpapers` and press SUPER+W.

## Keys

| Key | Action |
|---|---|
| SUPER (hold) | Show the bar · SUPER+SHIFT+B pins it |
| SUPER+T / B / E | Terminal / browser / files |
| SUPER+Space | Launcher |
| SUPER+W | Wallpaper picker (re-themes everything) |
| SUPER+Q | Close window · SUPER+V float |
| SUPER+1…0 | Workspace · +SHIFT moves the window |
| SUPER+S | Scratchpad · +SHIFT moves the window |
| SUPER+L | Lock · SUPER+SHIFT+M log out |

## Layout

Each top-level directory is a stow package mirroring `$HOME`; `dot-` becomes `.`
(`kitty/dot-config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`).
`--no-folding` links files one by one, so generated files never land in the repo.

```bash
stow -R hypr       # restow after adding a file (it isn't live until then)
stow -n -v hypr    # dry run
stow -D hypr       # unlink
```

Colors: `wallpaper <image>` (or `--pick`, `--random`, `--light`, `--dark`) sets the image and
runs matugen, which renders `matugen/dot-config/matugen/templates/*` into each app's config.
Generated files are not tracked; add a template instead of hardcoding a color.

## Development

`.githooks/pre-commit` runs on commit (`.githooks/pre-commit --all` for the whole repo):
stow check, Hyprland `--verify-config`, stylua, shellcheck, `zsh -n`, Python compile,
rofi theme parse, qmllint + qmlformat, and lua-language-server (`--all` only).

```bash
sudo pacman -S --needed stylua shellcheck lua-language-server qt6-declarative
```
