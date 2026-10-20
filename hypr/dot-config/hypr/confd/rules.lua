hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.layer_rule({
    name = "rofi",
    match = { namespace = "^rofi$" },
    blur = true,
    ignore_alpha = 0.3,
    animation = "popin 94%",
})

hl.layer_rule({
    name = "quickshell-bar",
    match = { namespace = "^quickshell-bar$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})

hl.layer_rule({
    name = "quickshell-dropdown",
    match = { namespace = "^quickshell-dropdown$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})

hl.layer_rule({
    name = "quickshell-catcher",
    match = { namespace = "^quickshell-catcher$" },
    no_anim = true,
})

hl.layer_rule({
    name = "notifications",
    match = { namespace = "^quickshell-notifications$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})
