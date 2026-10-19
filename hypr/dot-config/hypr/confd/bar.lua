local SUPER_KEYCODES = { [133] = true, [134] = true }
local KEY_PRESSED = 1

-- Persisted in a file so it survives config reloads; Bar.qml reads the same file.
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

hl.layer_rule({
    name = "quickshell-bar",
    match = { namespace = "^quickshell-bar$" },
    blur = true,
    ignore_alpha = 0.3,
    no_anim = true,
})
