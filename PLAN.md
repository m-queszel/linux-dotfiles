# Rice plan

Living decision log. ✅ decided · ❓ open · ⏳ in progress

## Decisions

| Area | Decision | Notes |
|---|---|---|
| Vibe | ✅ Cozy & soft | Rounded corners, soft colors, gentle animations |
| Palette | ✅ Generated from **any** wallpaper (matugen, `scheme-tonal-spot` = soft/muted) | One `wallpaper` command / SUPER-key rofi picker → awww sets it → matugen renders color files for Hyprland, waybar, kitty, rofi, mako, hyprlock, GTK → each app hot-reloads. Nothing runs between changes. Last choice restored at login |
| Light / dark | ✅ Auto from wallpaper brightness | Script measures average luminance and passes `-m light` or `-m dark` |
| Wallpaper tool | ✅ awww (animated transitions) | Not hyprpaper |
| Wallpapers | ✅ 5 in `~/Pictures` (3440×1440) | Move to `~/Pictures/Wallpapers/` |
| mainMod | ✅ SUPER | Was ALT |
| Layout | ✅ dwindle (for now) | Try master / scrolling later on the ultrawide |
| UI surfaces | ✅ Translucent + light blur (frosted) | ❌ Paper texture (solid surfaces + grain + hairline edge + shadow) was tried 2026-10-16 and rejected; don't reintroduce |
| Corner radius | ✅ **14px everywhere** | Hyprland `decoration.rounding = 14` with `rounding_power = 2` (plain circular corners, same as CSS `border-radius`); waybar pills, rofi, mako, hyprlock all use 14px |
| Mono font | ✅ 0xProto Nerd Font | Terminal, bar, launcher |
| UI font | ✅ Nunito (`ttf-nunito`) | Bar labels, notifications, GTK. 0xProto stays for terminal/code |
| Launcher | ✅ rofi centered card | 14px radius, search + icon list, palette from matugen, SUPER+Space |
| Wallpaper style | ✅ Anime / illustrated / lo-fi / pixel art, **paper feel** | Soft, easy on the eyes; paper-grain texture |
| Bar | ✅ Quickshell floating split pills | Left: workspace dots (active stretches with a spring, clickable). Right: volume / network / CPU+mem icons whose values slide out on hover, 12-hour clock with the date sliding out to its left. Hidden until SUPER is held (Hyprland sends `bar:peek` socket events, no process per keypress); slides down with a spring; SUPER+SHIFT+B pins it (stays shown, still floating; no reserved space). CPU/mem sampled only while visible. Replaced waybar 2026-10-16: waybar couldn't animate (GTK3) and its workspace clicks were broken on Lua configs |
| Notifications | ✅ Quickshell (replaced mako) | Countdown bar, hover-pause, X to close; colors from the wallpaper via Theme.qml |
| Gaps | ✅ 6 in / 12 out | Bar pills and notification margins use 12px too |
| Borders | ✅ 2px soft accent | Focused = matugen primary, unfocused = near-transparent surface tone. No looping border animation |
| Animations | ✅ Gentle springs | Windows pop in with a soft spring, workspaces slide; ~250ms |
| Blur | ✅ Light: size 5, 2 passes | Applies to bar, rofi, mako, kitty background |
| Lock screen | ✅ hyprlock, blurred desktop | Big clock + 14px password pill, matugen colors |
| Idle | ✅ hypridle: lock 15m, screen off 16m | No auto-suspend |
| Extra packages | ✅ libnotify installed | `notify-send` for scripts |

## Install list (all official repos, no AUR)

```
sudo pacman -S --needed awww matugen imagemagick quickshell hyprlock hypridle jq \
  papirus-icon-theme xdg-desktop-portal-gtk ttf-nunito adw-gtk-theme qt6ct capitaine-cursors
```

## Build order

1. ✅ Foundations: config split into `confd/` modules, mainMod → SUPER, env → uwsm, hyprpolkitagent + cliphist enabled, wallpapers → `~/Pictures/Wallpapers`
2. ✅ Wallpaper + matugen pipeline: `wallpaper` script (pick/random/light/dark, lock, thumbnail cache), awww-daemon unit, matugen templates for Hyprland borders + kitty, SUPER+W picker, install.sh seeding
3. ✅ Hyprland look: 6/12 gaps, 14px circular corners, 2px palette border, soft palette shadow, blur 5×2, "gentle" spring for windows, slidefade workspaces, no default wallpaper/logo, palette background before awww loads
4. ✅ Bar: Quickshell (`quickshell/` package, `quickshell.service`), SUPER-hold peek via `hl.dsp.event`, pin persisted in `$XDG_STATE_HOME/bar-pinned`, live matugen colors via `$XDG_STATE_HOME/theme/colors.json`
5. ✅ Launcher: rofi centered card (640px, 14px corners, Nunito, Papirus icons, frosted blur, popin), wallpaper colors via matugen `colors.rasi`, SUPER+Space toggles, apps launch in uwsm scopes
6. ✅ Terminal: kitty 90% translucent, 12px padding, 85% line height, beam cursor (no blink, no trail), round tabs; zsh (highlighting + ghost suggestions); starship prompt; animated 3D gem pointer cursor (kitty graphics, colors from the wallpaper palette: primary/tertiary/error)
7. ✅ Notifications: Quickshell notification server (replaced mako 2026-10-16: mako can't pause on hover, show a close button or a countdown). Frosted 14px cards top-right, slide in/out, newest on top, max 3; countdown bar pauses on hover; X closes; click opens the app; low 3 s, normal 5 s, app-requested timeouts honored, critical stays with error border
8. ✅ GTK / Qt / cursor: Capitaine cursor everywhere (XCURSOR_THEME + gsettings); GTK3 adw-gtk3 + GTK4 libadwaita recolored by matugen `gtk.css`, theme/color-scheme/Papirus icons switch light/dark in `wallpaper`; Qt via qt6ct (Fusion, matugen palette, Nunito / 0xProto, icons by mode, whole qt6ct.conf generated); KDE apps (Dolphin) ignore the qt6ct palette, so matugen also renders a `Matugen.colors` KDE scheme and install.sh sets `dolphinrc [UiSettings] ColorScheme=Matugen`
9. ✅ Lock / idle: hyprlock (blurred + dimmed desktop screenshot, 12-hour Nunito ExtraBold clock + date, 14px password pill; colors from matugen `hyprlock-colors.conf`), hypridle unit (lock 15 min, screen off 16 min, no suspend, lock before manual sleep), SUPER+L → `loginctl lock-session`
