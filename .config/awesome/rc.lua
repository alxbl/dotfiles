-- 0. Includes & stdlib {{{
local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")
-- Extensions
local lain          = require("lain")
local markup        = lain.util.markup
local utils         = require("utils")
local settings      = require("settings")
local keys          = require("keys")
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
local AUTO_FOCUS = false

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- -----------------------------------
-- Handle runtime errors after startup
-- -----------------------------------
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Don't show errors when rules try to spawn a client on a disconnected
        -- screen.
        if (err.text ~= "invalid screen number") then return end

        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "An error has occurred!",
                         text = tostring(err) })
        in_error = false
    end)
end

-- FIXME: Doesn't seem to work.
naughty.config.defaults.screen = awful.screen.primary
naughty.config.screen = awful.screen.primary

-- }}}
-- 1. Basic Configuration {{{
local CONFIG = settings.CONFIG
local EDITOR = os.getenv("EDITOR") or "vi"
local TERM   = os.getenv("TERMINAL") or "termite"

beautiful.init(CONFIG .. "themes/neo/theme.lua")

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    lain.layout.centerwork,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.corner.nw,
    -- lain.layout.cascade.tile,
    -- awful.layout.suit.magnifier,
}
-- }}}
-- 2. Startup {{{
awful.spawn("setxkbmap -option ctrl:nocaps")
awful.spawn("xset r rate 350 70")
utils.run_once(settings.autoruns)


-- }}}
-- 3. Workspace {{{
-- Create a wibox for each screen and add it
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Widgets {{{
bat =   lain.widget.bat({
    battery = "BAT0",
    settings = function()
        -- TODO: Color should not be hardcoded
        -- widget:set_markup(markup.font("Material Icons 14", markup("#FFFFFF", bat_header)))
        local fmt = string.format("<b>BAT0></b> %d%%", bat_now.perc)
        widget:set_markup(fmt)
    end
})
mem = lain.widget.mem({
    settings = function()
        local fmt = string.format("<b>MEM></b> %.1f/%.1fG (%d%%)", (mem_now.used / 1024.0), (mem_now.total / 1024.0), mem_now.perc)
        widget:set_markup(fmt)
    end
})

cpu = lain.widget.cpu({
    settings = function()
        local fmt = string.format("<b>CPU></b> %s%%", cpu_now.usage) -- TODO: sum all CPUs
        widget:set_markup(fmt)
    end
})
-- }}}


-- TODO: Global taglist?
-- TODO: screen added/removed signals to dynamically add/remove screens.
awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.layout  = awful.widget.layoutbox(s)
    s.taglist = awful.widget.taglist(s, filter_tag, keys.taglist_buttons)

    local bar = {
        layout = wibox.layout.align.horizontal,
        {

            layout = wibox.layout.fixed.horizontal,
            s.layout,
            s.taglist,
            wibox.container.margin(wibox.widget.systray(), 7),
        },
        nil,
        {
            layout = awful.widget.only_on_screen,
            screen = "primary",
            {
                bat.widget,
                mem.widget,
                cpu.widget,
                wibox.container.margin(wibox.widget.textclock("<b>NOW></b> %Y-%m-%d %R"), 0, 7),
                layout = wibox.layout.fixed.horizontal,
                spacing_widget = { color = "#00000000", widget = wibox.widget.separator, },
                spacing = 7,
            }
        }
    }

    s.taskbar = awful.wibar({ position = "top", screen = s, })
    s.taskbar:setup(bar)

    s.layout:buttons(gears.table.join(
       awful.button({ }, 1, function () awful.layout.inc( 1) end),
       awful.button({ }, 3, function () awful.layout.inc(-1) end),
       awful.button({ }, 4, function () awful.layout.inc( 1) end),
       awful.button({ }, 5, function () awful.layout.inc(-1) end)))
end)

-- vim:foldmethod=marker:foldlevel=0


require("rules")

-- TODO.
-- 6. Signal Hooks {{{
function on_focus_change(c, focused)
    if focused then
        c.border_color = beautiful.border_focus
        -- c.screen.tasklist.text = c.name
    else
        c.border_color = beautiful.border_normal
    end
end
client.connect_signal("manage", function (c) -- New client.
    -- if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

if AUTO_FOCUS then
    client.connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)
end

client.connect_signal("focus", function(c) on_focus_change(c, true) end)
client.connect_signal("unfocus", function (c) on_focus_change(c, false) end)

-- Title bars
client.connect_signal("request::titlebars", function(c)
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    local buttons = awful.util.table.join( -- Mouse button handler
    awful.button({ }, 1, function()
        client.focus = c
        c:raise()
        awful.mouse.client.move(c)
    end),
    awful.button({ }, 3, function()
        client.focus = c
        c:raise()
        awful.mouse.client.resize(c)
    end)
    )

    awful.titlebar(c, {size = 16}) : setup {
        { layout = wibox.layout.fixed.horizontal() },
        {
            {
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { layout = wibox.layout.fixed.horizontal() },
        layout = wibox.layout.align.horizontal
    }
end)

