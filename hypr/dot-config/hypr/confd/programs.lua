-- Full path: Hyprland's PATH may not include ~/.local/bin.
local bin = os.getenv("HOME") .. "/.local/bin/"

return {
    terminal = "kitty",
    fileManager = "dolphin",
    browser = "firefox",
    menu = "pkill -x rofi || rofi -show drun",
    wallpaperPicker = bin .. "wallpaper --pick",
    capture = bin .. "capture",
}
