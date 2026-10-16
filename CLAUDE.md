# CLAUDE.md — linux-dotfiles

Personal dotfiles for an Arch Linux + Hyprland desktop, managed with GNU Stow.

## Hard rules

- **Never run `git commit` or `git push`** (or amend/rebase/merge/tag). The owner commits manually.
  Allowed: `git status`, `diff`, `log`, `show`, `blame`, `fetch`, `pull`, `stash` / `stash pop`.
  When a change is done, list the changed files and suggest a commit message.
- **Hyprland config is Lua** (`hyprland.lua`, Hyprland ≥ 0.55). Never write hyprlang syntax
  (`bind =`, `exec-once =`, `windowrulev2 =`, `$var =`) into it. Translate online guides to Lua.
  hyprpaper / hyprlock / hypridle / hyprsunset still use hyprlang `.conf` — that's correct for them.
- **Validate before declaring done:** `.githooks/pre-commit --all` must pass
  (runs `Hyprland --verify-config`, `stylua --check`, `shellcheck`, `lua-language-server --check`).
- Never edit `~/.config/...` targets directly for tracked files — edit the file in this repo
  (they're the same file via symlink, but think in terms of the repo).

## System

- Arch Linux, Hyprland 0.56 (Lua config), **uwsm**-managed session, Nvidia (`nvidia-open`).
- Monitor: 3440x1440 @ 240 Hz. Terminal: kitty. Launcher: rofi 2.0 (native Wayland). Browser: Firefox.
- `hyprctl dispatch` takes Lua: `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`.
  Legacy `hyprctl dispatch workspace 3` is broken — don't use it in scripts.
- API reference: `/usr/share/hypr/stubs/hl.meta.lua` (also wired into `.luarc.json` for the LSP).

## Layout

```
<package>/dot-config/<app>/...   → stowed to ~/.config/<app>/...   (dot- prefix → ".")
.githooks/                        git hooks (core.hooksPath), not a stow package
.stowrc                           --dotfiles --target=~
install.sh                        bootstrap: hooks path + stow all packages
```
- One stow package per app (`hypr/`, `kitty/`, `waybar/`, ...). Add a new app by creating
  `<app>/dot-config/<app>/`, moving the config in, then `stow --adopt <app>` and `git diff` (should be empty).
- Split large Hyprland config into `hypr/dot-config/hypr/confd/*.lua`, loaded with
  `require("confd/<name>")`. Directory names must not contain dots.
- Palette lives in one place and every app imports it; never duplicate hex values across apps.

## Engineering priorities

The owner values best practices, **speed and low memory use**:
- Prefer event-driven over polling (Hyprland event socket `.socket2.sock`, `deflisten`, waybar `signal`)
  over `interval`-based scripts; never sub-second polls.
- Prefer fewer, lighter daemons (hyprpaper over animated wallpaper daemons, mako/dunst over heavier
  notification centers) unless a feature is explicitly wanted.
- Avoid always-rendering effects (`borderangle` with `style = "loop"`); keep blur passes low.
- Daemons start as **systemd user units** (`systemctl --user enable --now ...`), apps via `uwsm app -- <cmd>`.
  Session env vars go in `uwsm/dot-config/uwsm/env` (and `env-hyprland`), not `hl.env`.
- Scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, shellcheck-clean, no hardcoded `/home/<user>`.
- Lua: formatted with stylua (`stylua.toml`), small modules, comments only where intent isn't obvious.
- Measure before/after adding a component (`smem -tk` or `ps_mem`).
