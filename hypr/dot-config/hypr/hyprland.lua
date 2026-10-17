-- Hyprland 0.56 (Lua config) entry point. Each concern lives in its own module under confd/.
-- Validate before saving: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
-- API reference: /usr/share/hypr/stubs/hl.meta.lua

require("confd/monitors")
require("confd/look")
require("confd/input")
require("confd/binds")
require("confd/rules")
require("confd/bar")
