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
    name = "quickshell-desktop",
    match = { namespace = "^quickshell-desktop$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})

hl.layer_rule({
    name = "quickshell-corners",
    match = { namespace = "^quickshell-corners$" },
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

hl.window_rule({
    name = "thunar-progress",
    match = { class = "^thunar$", title = "^File Operation Progress$" },
    float = true,
    move = "monitor_w-window_w-24 monitor_h-window_h-24",
})

hl.layer_rule({
    name = "quickshell-glitch",
    match = { namespace = "^quickshell-glitch$" },
    no_anim = true,
})

hl.window_rule({
    name = "thunar-quasar",
    match = { class = "^thunar$", float = false },
    no_blur = true,
    no_shadow = true,
})

hl.layer_rule({
    name = "quickshell-drawer",
    match = { namespace = "^quickshell-drawer$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})

hl.layer_rule({
    name = "quickshell-quasar",
    match = { namespace = "^quickshell-quasar$" },
    no_anim = true,
})
