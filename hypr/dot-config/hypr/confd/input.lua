-- Keyboard, mouse and touchpad.
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0, -- -1.0 to 1.0; 0 = no change
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
