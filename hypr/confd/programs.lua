local bin = os.getenv("HOME") .. "/.local/bin/"

return {
    terminal = "kitty",
    fileManager = "thunar",
    browser = "firefox",
    menu = "pkill -x rofi || rofi -show drun",
    wallpaperPicker = bin .. "wallpaper --pick",
    capture = bin .. "capture",
}
