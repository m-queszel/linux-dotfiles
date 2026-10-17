-- Auto-hiding bar (Quickshell, ~/.config/quickshell/Bar.qml): shown while SUPER is held,
-- SUPER+SHIFT+B pins it. State reaches Quickshell as custom socket events, so no process is
-- spawned per keypress:  bar:peek:1/0  and  bar:pin:1/0
-- Both float the bar over windows; pinning just keeps it shown.

local SUPER_KEYCODES = { [133] = true, [134] = true } -- xkb keycodes of Super_L / Super_R
local KEY_PRESSED = 1

-- Pinned state lives in a file so it survives config reloads (every wallpaper change reloads)
-- and Quickshell restarts (Bar.qml reads the same file).
local stateDir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local pinFile = stateDir .. "/bar-pinned"

local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
    end
    return f ~= nil
end

local pinned = fileExists(pinFile)
local superHeld = false

local function emit(name, on)
    hl.dispatch(hl.dsp.event("bar:" .. name .. ":" .. (on and "1" or "0")))
end

local function setPinned(on)
    pinned = on
    if on then
        local f = io.open(pinFile, "w")
        if f then
            f:close()
        end
    else
        os.remove(pinFile)
    end
    emit("pin", on)
end

-- Key events fire for every key; return immediately unless it's SUPER changing state.
hl.on("input.keyboard.key", function(keycode, _, state)
    if not SUPER_KEYCODES[keycode] then
        return
    end
    local down = state == KEY_PRESSED
    if down == superHeld then
        return
    end
    superHeld = down
    emit("peek", down)
end)

hl.bind("SUPER + SHIFT + B", function()
    setPinned(not pinned)
end, { description = "Pin / unpin the bar" })

-- Blur behind the pills only (transparent areas skipped). Quickshell animates the bar itself.
hl.layer_rule({
    name = "quickshell-bar",
    match = { namespace = "^quickshell-bar$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})
