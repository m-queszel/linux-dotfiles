# linux-dotfiles

Arch Linux + Hyprland (Lua config) dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

| | |
|---|---|
| Compositor | Hyprland 0.56 (`hyprland.lua`), uwsm session |
| Terminal | kitty |
| Launcher | rofi 2.0 |

*Rice in progress.*

## Install

```bash
sudo pacman -S --needed git stow
git clone git@github.com:m-queszel/linux-dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```
Requires Hyprland ≥ 0.55 (Lua config).

## Layout

Each top-level directory is a stow package that mirrors `$HOME`. The `dot-` prefix
becomes `.` when stowed (`--dotfiles`), so `kitty/dot-config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`.

```bash
stow hypr          # link one package (options come from .stowrc)
stow -n -v hypr    # dry run
stow -R hypr       # restow after adding files
stow -D hypr       # unlink
```

## Development

Checks run automatically on commit (`.githooks/pre-commit`):
Hyprland `--verify-config`, `stylua --check`, `shellcheck`. Full run including the Lua language server:

```bash
.githooks/pre-commit --all
```
Tools: `sudo pacman -S --needed stow lua-language-server stylua shellcheck`.
