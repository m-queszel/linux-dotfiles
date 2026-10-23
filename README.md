# linux-dotfiles

A cozy, soft Arch Linux + Hyprland rice. Every color comes from the wallpaper.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

| | |
|---|---|
| Compositor | Hyprland 0.56 (Lua config), uwsm session |
| Shell UI | Quickshell: auto-hiding bar, notifications |
| Launcher | rofi 2.0 |
| Terminal | kitty, zsh, starship (colors from matugen), animated pixel prompt + starlit strip, armillary-sphere title screen with programming quotes (`quotes-update`); recolors live on wallpaper change (`pixel-art-refresh`); `ls` and completion colors from the theme (`ls-colors` template) |
| Theming | matugen from the wallpaper (awww): Hyprland, apps, GTK, Qt, lock screen |
| Lock / idle | hyprlock, hypridle (lock 15 min, screen off 16 min) |
| Media drawer | Spotify (spotify-player) and Discord (discordo) in a glass drawer on the right edge (optional, see below) |

## Install

```bash
sudo pacman -S --needed git stow hyprland uwsm kitty rofi quickshell awww matugen \
  imagemagick hyprlock hypridle hyprpolkitagent cliphist wl-clipboard libnotify \
  zsh zsh-autosuggestions zsh-syntax-highlighting starship python \
  ttf-nunito ttf-0xproto-nerd papirus-icon-theme capitaine-cursors \
  adw-gtk-theme qt6ct xdg-desktop-portal-gtk wireplumber playerctl
git clone git@github.com:m-queszel/linux-dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh   # link, seed colors, enable user services
chsh -s /usr/bin/zsh            # then log out and back in
```

Then pick a wallpaper: put images in `~/Pictures/Wallpapers` and press SUPER+W.

## Media drawer (optional)

Spotify and Discord run as terminal apps in a drawer on the right screen edge. Skip this section
if you don't want them; SUPER+S and SUPER+D then just show a short notice.

```bash
sudo pacman -S --needed spotify-player jq base-devel git
cd ~/dotfiles/discordo && BUILDDIR=~/.cache/makepkg/build SRCDEST=~/.cache/makepkg/src \
  PKGDEST=~/.cache/makepkg/pkg makepkg -sirc   # builds discordo from a pinned, reviewed commit
```

**Spotify** needs Premium. The first SUPER+S opens your browser once to approve the login.
Playlists can hang on "Loading" because the built-in app ID is shared by every user and runs out of
quota. Give it your own (free, 3 minutes):

1. At <https://developer.spotify.com/dashboard>, create an app with the redirect URI
   `http://127.0.0.1:8989/login` and the Web API ticked.
2. Copy its Client ID (not the secret) into a file only you can read:
   `printf '%s\n' YOUR_CLIENT_ID > ~/.config/spotify-player/client_id && chmod 600 ~/.config/spotify-player/client_id`
3. Quit Spotify with `q`, press SUPER+S and approve once more.

**Discord**: SUPER+D, pick the QR tab and scan it with the Discord phone app. It needs a system
keyring (KWallet or `gnome-keyring`) to store the login. Third-party clients break Discord's terms
of service, so there is a small risk of an account ban.

**Logins stay on your machine.** Nothing here stores a credential in the repo: Spotify keeps its tokens
in `~/.cache/spotify-player/`, Discord keeps its token in your keyring, and the Spotify Client ID file
is git-ignored.

**Mouse:** hover the right edge and click a tab. Right-click inside an app for its menu (play, next,
lyrics, search / join voice, mute, deafen, copy, paste). Shift+drag selects text. In Discord,
double-click a voice channel to join or leave it; `v`, Alt+V and Alt+D do the same from the keyboard.

## Keys

| Key | Action |
|---|---|
| SUPER (hold) | Show the bar · SUPER+SHIFT+B pins it |
| SUPER+T / B / E | Terminal / browser / files |
| SUPER+Space | Launcher |
| SUPER+W | Wallpaper picker (re-themes everything) |
| SUPER+Q | Close window · SUPER+V float |
| SUPER+1…0 | Workspace · +SHIFT moves the window |
| SUPER+S / D | Spotify / Discord drawer · same key again, Esc or a click outside closes it |
| SUPER+` | Scratchpad · +SHIFT moves the window |
| SUPER+L | Lock · SUPER+SHIFT+M log out |

## Layout

Each top-level directory holds one app's files and is linked into place with GNU Stow by `./link`:
`kitty/kitty.conf` → `~/.config/kitty/kitty.conf`. The exceptions are `home/` → `~` (`dot-` becomes `.`),
`bin/` → `~/.local/bin`, `systemd/` → `~/.config/systemd/user` and `thunar/` → `~/.config/Thunar`.
Files are linked one by one, so generated files never land in the repo.

```bash
./link hypr            # relink after adding a file (it isn't live until then)
./link --check         # what isn't linked yet
./link --unlink hypr   # remove the links
```

Colors: `wallpaper <image>` (or `--pick`, `--random`, `--light`, `--dark`) sets the image and
runs matugen, which renders `matugen/templates/*` into each app's config.
Generated files are not tracked; add a template instead of hardcoding a color.

## Development

`.githooks/pre-commit` runs on commit (`.githooks/pre-commit --all` for the whole repo):
link check, Hyprland `--verify-config`, stylua, shellcheck, `zsh -n`, Python compile,
rofi theme parse, qmllint + qmlformat, and lua-language-server (`--all` only).

```bash
sudo pacman -S --needed stylua shellcheck lua-language-server qt6-declarative
```
