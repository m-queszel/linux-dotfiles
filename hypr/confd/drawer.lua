local M = {
    apps = { spotify = "spotify_player", discord = "discordo" },
    order = { spotify = 0, discord = 1 },
    shown = nil,
    pending = nil,
    menu = false,
}

local kitty = "kitty --single-instance --instance-group drawer --config "
    .. os.getenv("HOME")
    .. "/.config/kitty/drawer.conf"
local rail = { w = 76, top = 28, h = 178 }
local gap = 14
local tick = 4
local follow = hl.get_config("input.follow_mouse") or 1
local warps = hl.get_config("cursor.no_warps") or false

local function bezier(x1, y1, x2, y2)
    local function b(t, a, c)
        return 3 * a * (1 - t) ^ 2 * t + 3 * c * (1 - t) * t * t + t ^ 3
    end
    return function(x)
        if x <= 0 then
            return 0
        elseif x >= 1 then
            return 1
        end
        local lo, hi = 0, 1
        for _ = 1, 24 do
            local mid = (lo + hi) / 2
            if b(mid, x1, x2) < x then
                lo = mid
            else
                hi = mid
            end
        end
        return b(lo, y1, y2)
    end
end

local snap = bezier(0.23, 1, 0.32, 1)
local enter = bezier(0.05, 0.7, 0.1, 1)
local leave = bezier(0.3, 0, 0.8, 0.15)

local function sel(app)
    return "class:^drawer-" .. app .. "$"
end

local last = { x = 0, y = 0, w = 1150, h = 850, out = 1170 }

local function geometry()
    local m = hl.get_active_monitor()
    if not m then
        return last
    end
    local W, H = m.width / m.scale, m.height / m.scale
    local top = type(m.reserved) == "table" and m.reserved.top or 0
    local w = math.floor(math.min(1150, math.max(720, W * 0.33)) + 0.5)
    local h = math.floor(math.min(850, math.max(520, H * 0.6)) + 0.5)
    last = {
        x = m.x + W - gap - w,
        y = m.y + top + math.floor((H - top - h) / 2 + 0.5),
        w = w,
        h = h,
        out = m.x + W + 20,
    }
    return last
end

local st = {}
local tween

local function place(app, g)
    local s = st[app]
    local v = string.format("%.3f", math.max(0.01, s.a))
    hl.dispatch(
        hl.dsp.window.move({ x = math.floor(g.x + s.x + 0.5), y = math.floor(g.y + s.y + 0.5), window = sel(app) })
    )
    hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity", value = v, window = sel(app) }))
    hl.dispatch(hl.dsp.window.set_prop({ prop = "opacity_inactive", value = v, window = sel(app) }))
end

local function unpark(app, g, s)
    if st[app] then
        return
    end
    st[app] = s
    hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace().id, follow = false, window = sel(app) }))
    hl.dispatch(hl.dsp.window.pin({ action = "enable", window = sel(app) }))
    hl.dispatch(hl.dsp.window.resize({ x = g.w, y = g.h, window = sel(app) }))
    place(app, g)
end

local function park(app)
    st[app] = nil
    hl.dispatch(hl.dsp.window.pin({ action = "disable", window = sel(app) }))
    hl.dispatch(hl.dsp.window.move({ workspace = "special:drawer", follow = false, window = sel(app) }))
end

local function emit(state, g)
    hl.dispatch(hl.dsp.event(string.format("drawer>>%s,%d,%d,%d,%d", state, g.x, g.y, g.w, g.h)))
end

local function focus(app)
    hl.config({ input = { follow_mouse = app and 2 or follow } })
    if app then
        hl.config({ cursor = { no_warps = true } })
        hl.dispatch(hl.dsp.focus({ window = sel(app) }))
        hl.config({ cursor = { no_warps = warps } })
    end
end

local function animate(ms, ease, goal, done)
    if tween then
        tween.timer:set_enabled(false)
    end
    local g = geometry()
    local from = {}
    for app in pairs(goal) do
        local s = st[app]
        from[app] = { x = s.x, y = s.y, a = s.a }
    end
    local t = { elapsed = 0 }
    local function step(p)
        local e = ease(p)
        for app, to in pairs(goal) do
            if st[app] then
                local f = from[app]
                st[app] = { x = f.x + (to.x - f.x) * e, y = f.y + (to.y - f.y) * e, a = f.a + (to.a - f.a) * e }
                place(app, g)
            end
        end
    end
    t.timer = hl.timer(function()
        t.elapsed = t.elapsed + tick
        if t.elapsed < ms then
            step(t.elapsed / ms)
            return
        end
        t.timer:set_enabled(false)
        if tween == t then
            tween = nil
        end
        step(1)
        if done then
            done()
        end
    end, { timeout = tick, type = "repeat" })
    tween = t
end

local function show(app)
    local g = geometry()
    for other in pairs(st) do
        if other ~= app then
            park(other)
        end
    end
    unpark(app, g, { x = g.out - g.x, y = 0, a = 1 })
    M.shown = app
    focus(app)
    emit(app, g)
    animate(400, enter, { [app] = { x = 0, y = 0, a = 1 } })
end

local function hide()
    local app, g = M.shown, geometry()
    if not app then
        return
    end
    M.shown = nil
    focus(nil)
    emit("none", g)
    local goal = {}
    for a, s in pairs(st) do
        goal[a] = a == app and { x = g.out - g.x, y = s.y, a = s.a } or { x = s.x, y = s.y, a = 0 }
    end
    animate(200, leave, goal, function()
        for a in pairs(goal) do
            park(a)
        end
    end)
end

local function switch(from, to)
    local g = geometry()
    local dir = M.order[to] > M.order[from] and 1 or -1
    local d = g.h * 0.1
    for other in pairs(st) do
        if other ~= from and other ~= to then
            park(other)
        end
    end
    unpark(from, g, { x = 0, y = 0, a = 1 })
    unpark(to, g, { x = st[from].x, y = dir * d, a = 0 })
    M.shown = to
    focus(to)
    emit(to, g)
    animate(180, snap, { [from] = { x = 0, y = -dir * d, a = 0 }, [to] = { x = 0, y = 0, a = 1 } }, function()
        park(from)
    end)
end

local function ensure(app, after)
    if hl.get_window(sel(app)) then
        after()
        return
    end
    if not os.execute("command -v " .. M.apps[app] .. " >/dev/null 2>&1") then
        hl.notification.create({
            text = M.apps[app] .. " is not installed (see the README's Media drawer section)",
            timeout = 4000,
        })
        return
    end
    M.pending = { app = app, after = after }
    hl.exec_cmd(kitty .. " --class drawer-" .. app .. " " .. M.apps[app])
end

function M.toggle(app)
    if not M.apps[app] then
        return
    end
    if M.shown == app then
        hide()
    elseif M.shown then
        local from = M.shown
        ensure(app, function()
            switch(from, app)
        end)
    else
        ensure(app, function()
            show(app)
        end)
    end
end

M.hide = hide

function M.sync()
    emit(M.shown or "none", geometry())
end

function M.click()
    if not M.shown or M.menu then
        return
    end
    local c, g = hl.get_cursor_pos(), geometry()
    if not c then
        return
    end
    local modal = c.x >= g.x and c.x <= g.x + g.w and c.y >= g.y and c.y <= g.y + g.h
    local tabs = c.x >= g.x - rail.w and c.x < g.x and c.y >= g.y + rail.top and c.y <= g.y + rail.top + rail.h
    if not modal and not tabs then
        hide()
    end
end

hl.bind("escape", function()
    hide()
end, { non_consuming = true })

hl.window_rule({
    name = "drawer",
    match = { class = "^drawer-.*$" },
    float = true,
    no_anim = true,
    no_shadow = true,
    size = { 1150, 850 },
    move = { "monitor_w+40", "0" },
})

hl.on("window.open", function(w)
    local app = w and w.class and w.class:match("^drawer%-(%a+)$")
    if app and M.pending and M.pending.app == app then
        local after = M.pending.after
        M.pending = nil
        after()
    end
end)

hl.on("window.close", function(w)
    local app = w and w.class and w.class:match("^drawer%-(%a+)$")
    if app then
        st[app] = nil
    end
    if app and app == M.shown then
        M.shown = nil
        focus(nil)
        emit("none", geometry())
    end
end)

for _, w in ipairs(hl.get_windows()) do
    local app = w.class:match("^drawer%-(%a+)$")
    if app and w.workspace and w.workspace.name ~= "special:drawer" then
        M.shown = app
        st[app] = { x = 0, y = 0, a = 1 }
        hl.config({ input = { follow_mouse = 2 } })
    end
end

Drawer = M

return M
