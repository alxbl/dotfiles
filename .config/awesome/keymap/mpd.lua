local string, table, type = string, table, type
local gears         = require("gears")
local awful         = require("awful")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")


local function mpc(cmd)
    awful.spawn.with_shell("mpc " .. cmd)
    beautiful.mpd.update()
end

-- -----------------------------------------------------------------------------
-- MPD client hotkeys
-- -----------------------------------------------------------------------------
local CONFIG_DIR = string.format("%s/.config/awesome/", os.getenv("HOME"))
local VARS = gears.protected_call(dofile, CONFIG_DIR .. "vars.lua")

return awful.util.table.join(
    awful.key({ VARS.altkey, "Control" }, "Up", function () mpc("toggle") end),
    awful.key({ VARS.altkey, "Control" }, "Down", function () mpc("stop") end),
    awful.key({ VARS.altkey, "Control" }, "Left", function () mpc("prev") end),
    awful.key({ VARS.altkey, "Control" }, "Right", function () mpc("next") end),

    awful.key({ VARS.altkey }, "0",    function () 
        local common = { text = "MPD widget ", position = "top_middle", timeout = 2 }
        if beautiful.mpd.timer.started then
            beautiful.mpd.timer:stop()
            common.text = common.text .. lain.util.markup.bold("OFF")
        else
            beautiful.mpd.timer:start()
            common.text = common.text .. lain.util.markup.bold("ON")
        end
        naughty.notify(common)
    end),
    -- ALSA volume control
    awful.key({ VARS.altkey }, "Up", function ()
        os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
        beautiful.volume.update()
    end),
    awful.key({ VARS.altkey }, "Down", function ()
        os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
        beautiful.volume.update()
    end),
    awful.key({ VARS.altkey }, "m", function ()
        os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
        beautiful.volume.update()
    end),
    awful.key({ VARS.altkey, "Control" }, "m", function ()
        os.execute(string.format("amixer -q set %s 100%%", beautiful.volume.channel))
        beautiful.volume.update()
    end),
    awful.key({ VARS.altkey, "Control" }, "0", function ()
        os.execute(string.format("amixer -q set %s 0%%", beautiful.volume.channel))
        beautiful.volume.update()
    end)
)
