-- Window, layer and workspace rules.
-- https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from all apps
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
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

-- Launcher card: frosted background, gentle pop-in
hl.layer_rule({
    name = "rofi",
    match = { namespace = "^rofi$" },
    blur = true,
    ignore_alpha = 0.3,
    animation = "popin 94%",
})

-- Notifications (Quickshell): frosted like the bar; Quickshell animates the cards itself
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
