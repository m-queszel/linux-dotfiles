local ok, colors = pcall(require, "colors")
if not ok then
    colors = { primary = "b86b4f", outline_variant = "4f4539", shadow = "000000", surface = "1a120d" }
end

local function rgba(hex, alpha)
    return string.format("rgba(%s%02x)", hex, math.floor(alpha * 255 + 0.5))
end

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = rgba(colors.primary, 1),
            inactive_border = rgba(colors.outline_variant, 0.4),
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 14,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 16,
            render_power = 3,
            offset = { 0, 4 },
            color = rgba(colors.shadow, 0.35),
            color_inactive = rgba(colors.shadow, 0.2),
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            vibrancy = 0.17,
            popups = false,
            special = false,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = "rgb(" .. colors.surface .. ")",
    },
})

hl.curve("gentle", { type = "spring", mass = 1, stiffness = 200, dampening = 24 })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "gentle" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "gentle", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "gentle" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "quick" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "slidefadevert 15%",
})
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
