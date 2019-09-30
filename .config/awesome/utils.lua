local awful    = require("awful")
local settings = require("settings")
local mod = {}

mod.run_once = function(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        f = cmd
        spc = cmd:find(" ")
        if spc then
            f = cmd:sub(0, spc-1)
        end
        awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", f, cmd))
    end
end

mod.pick_wnd    = function() awful.spawn("rofi -show window") end
mod.run_cmd     = function() awful.spawn("rofi -show run") end
mod.lock_screen = function() awful.spawn(settings.lock_cmd) end
mod.shell       = function() awful.spawn(settings.terminal) end
mod.screenshot  = function() awful.spawn("flameshot gui") end

-- Custom tagbar display filter.
mod.filter_tag = function(tag)
    local urgent = false
    local clients = tag:clients()
    for k, c in pairs(clients) do
        if c.urgent then return true end
    end
    return tag.selected
end


mod.toggle_fullscreen = function(c)
   c.fullscreen = not c.fullscreen
   c:raise()
end

mod.toggle_maximize = function(c)
   c.maximized = not c.maximized
   c:raise()
end

return mod
