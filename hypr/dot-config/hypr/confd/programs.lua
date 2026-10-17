-- Default applications, shared by keybinds and autostart.
-- Scripts use a full path: Hyprland's PATH may not include ~/.local/bin.
local bin = os.getenv("HOME") .. "/.local/bin/"

return {
    terminal = "kitty",
    fileManager = "dolphin",
    browser = "firefox",
    menu = "pkill -x rofi || rofi -show drun", -- same key opens and closes it
    wallpaperPicker = bin .. "wallpaper --pick",
}
