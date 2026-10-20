local ok, colors = pcall(require, "colors")
if not ok then
    colors = {
        primary = "b86b4f",
        tertiary = "cbc992",
        outline_variant = "52443c",
        surface = "1a120d",
    }
end

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.06,
        shadow = {
            enabled = true,
            sharp = true,
            range = 0,
            offset = { 7, 7 },
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
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

hl.config({
    general = {
        col = {
            active_border = "rgb(" .. colors.primary .. ")",
            inactive_border = "rgb(" .. colors.outline_variant .. ")",
        },
    },
    decoration = {
        shadow = {
            color = "rgb(" .. colors.tertiary .. ")",
            color_inactive = "rgb(" .. colors.tertiary .. ")",
        },
    },
})

hl.curve("gentle", { type = "spring", mass = 1, stiffness = 200, dampening = 24 })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "emphasizedDecel" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "gentle" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "gentle", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedAccel", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, spring = "gentle" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "quick" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "emphasizedAccel", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3,
    bezier = "easeOutQuint",
    style = "slidefadevert 15%",
})
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
