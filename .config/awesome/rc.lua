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
-- -----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------
local AUTO_FOCUS = false
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        findme = cmd
        firstspace = cmd:find(" ")
        if firstspace then
            findme = cmd:sub(0, firstspace-1)
        end
        awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
    end
end

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
local MOD    = "Mod4"
local HOME   = os.getenv("HOME")
local CONFIG = HOME .. "/.config/awesome/"
local EDITOR = os.getenv("EDITOR") or "vi"
local TERM   = os.getenv("TERMINAL") or "termite"

beautiful.init(CONFIG .. "themes/neo/theme.lua")

awful.layout.layouts = {
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.fair,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    lain.layout.centerwork,
    -- lain.layout.cascade.tile
}
-- }}}
-- 2. Startup {{{
local lock_cmd = "i3lock -c1f67b1 -u -i " .. CONFIG .. "lock.png"
awful.spawn("setxkbmap -option ctrl:nocaps")
awful.spawn("xset r rate 350 70")
run_once({
    -- "unclutter -root",
    "compton -i 0.95", -- -i 0.8
    "fcitx",
    "flameshot",
    "nm-applet",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "xautolock -time 5 -locker \"" .. lock_cmd .. "\""
})

local function pick_wnd()    awful.spawn("rofi -show window") end
local function run_cmd()     awful.spawn("rofi -show run") end
local function lock_screen() awful.spawn(lock_cmd) end

-- }}}
-- 3. Workspace {{{
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ MOD }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ MOD }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local taskbar_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

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

function filter_tag(tag)
    -- Show tags with urgent clients and the selected tag.
    local urgent = false
    local clients = tag:clients()
    for k, c in pairs(clients) do
        if c.urgent then return true end
    end
    return tag.selected
end

-- TODO: Global taglist?
-- TODO: screen added/removed signals to dynamically add/remove screens.
awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.layout  = awful.widget.layoutbox(s)
    s.taglist = awful.widget.taglist(s, filter_tag, taglist_buttons)

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

-- }}}
--  4. Key bindings {{{
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
KEYS = gears.table.join(
    -- Core
    awful.key({ MOD,           }, "s",      hotkeys_popup.show_help,                {description="show help",            group = "awesome"}),
    awful.key({ MOD, "Control" }, "r", awesome.restart,                             {description = "reload awesome",     group = "awesome"}),
    awful.key({ MOD, "Shift"   }, "q", awesome.quit,                                {description = "quit awesome",       group = "awesome"}),
    awful.key({ MOD,           }, "Return", function () awful.spawn(TERM) end,      {description = "open terminal",      group = "awesome"}),
    awful.key({ MOD,           }, "Tab", pick_wnd,                                  {description = "open window picker", group = "awesome"}),
    awful.key({ "Mod1",        }, "Tab", pick_wnd,                                  {description = "open window picker", group = "awesome"}),
    awful.key({ MOD,           }, "r", run_cmd,                                     {description = "open launcher",      group = "awesome"}),
    awful.key({ MOD,           }, "p", function() awful.spawn("flameshot gui") end, {description = "take screenshot",    group = "awesome"}),
    awful.key({ "Control", "Mod1"  }, "l", lock_screen,                             {description = "lock screen",        group = "awesome"}),

    -- TODO: Carousel
    awful.key({ MOD,           }, "y", function() awful.spawn("bash " .. HOME.. "/.screenlayout/laptop.sh") end, {description = "Switch to laptop",    group = "awesome"}),
    awful.key({ MOD,           }, "i", function() awful.spawn("bash " .. HOME .. "/.screenlayout/work-dual.sh") end, {description = "Switch to dual screen",    group = "awesome"}),

    -- Layouts
    awful.key({ MOD,           }, "Left",   awful.tag.viewprev,        {description = "view previous",  group = "tag"}),
    awful.key({ MOD,           }, "Right",  awful.tag.viewnext,        {description = "view next",      group = "tag"}),
    awful.key({ MOD,           }, "Escape", awful.tag.history.restore, {description = "go back",        group = "tag"}),

    awful.key({ MOD,           }, "l",     function () awful.tag.incmwfact( 0.05)          end, {description = "increase master width factor", group = "layout"}),
    awful.key({ MOD,           }, "h",     function () awful.tag.incmwfact(-0.05)          end, {description = "decrease master width factor", group = "layout"}),
    awful.key({ MOD, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end, {description = "increase the number of master clients", group = "layout"}),
    awful.key({ MOD, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end, {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ MOD, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end, {description = "increase the number of columns", group = "layout"}),
    awful.key({ MOD, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end, {description = "decrease the number of columns", group = "layout"}),
    awful.key({ MOD,           }, "space", function () awful.layout.inc( 1)                end, {description = "select next", group = "layout"}),
    awful.key({ MOD, "Shift"   }, "space", function () awful.layout.inc(-1)                end, {description = "select previous", group = "layout"}),

    -- Clients
    awful.key({ MOD,           }, "j", function ()  awful.client.focus.byidx( 1)    end, {description = "focus next by index",                group = "client"}),
    awful.key({ MOD,           }, "k", function ()  awful.client.focus.byidx(-1)    end, {description = "focus previous by index",            group = "client"}),
    awful.key({ MOD, "Shift"   }, "j", function ()  awful.client.swap.byidx(  1)    end, {description = "swap with next client by index",     group = "client"}),
    awful.key({ MOD, "Shift"   }, "k", function ()  awful.client.swap.byidx( -1)    end, {description = "swap with previous client by index", group = "client"}),
    awful.key({ MOD,           }, "u", awful.client.urgent.jumpto,                      {description = "jump to urgent client",              group = "client"}),

    -- awful.key({ MOD,           }, "Tab",
    --     function ()
    --         awful.client.focus.history.previous()
    --         if client.focus then
    --             client.focus:raise()
    --         end
    --     end,
    --     {description = "switch to previous client", group = "client"}),


    -- Screens
    awful.key({ MOD, "Control" }, "j", function () awful.screen.focus_relative( 1) end, {description = "focus the next screen",     group = "screen"}),
    awful.key({ MOD, "Control" }, "k", function () awful.screen.focus_relative(-1) end, {description = "focus the previous screen", group = "screen"}),
    awful.key({ MOD,           }, "b", function () awful.screen.focused().taskbar.visible = not awful.screen.focused().taskbar.visible end, {description = "toggle task bar"}),

    -- Unsorted yet.
    awful.key({ MOD, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- TODO: lain volume widget + dynamic sink selection
    awful.key({}, "XF86AudioRaiseVolume", function() awful.spawn("sh -c \"pactl set-sink-mute 4 false ; pactl set-sink-volume 0 +5%\"") end),
    awful.key({}, "XF86AudioLowerVolume", function() awful.spawn("sh -c \"pactl set-sink-mute 4 false ; pactl set-sink-volume 0 -5%\"") end),
    awful.key({}, "XF86MonBrightnessDown", function() awful.spawn("brillo -U 4") end),
    awful.key({}, "XF86MonBrightnessUp", function() awful.spawn("brillo -A 4") end)
)

CLIENT_KEYS = gears.table.join(
    awful.key({ MOD,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ MOD, "Shift"   }, "c",      function (c) c:kill()                         end, {description = "close", group = "client"}),
    awful.key({ MOD, "Control" }, "space",  awful.client.floating.toggle                     , {description = "toggle floating", group = "client"}),
    awful.key({ MOD, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, {description = "move to master", group = "client"}),
    awful.key({ MOD,           }, "o",      function (c) c:move_to_screen()               end, {description = "move to screen", group = "client"}),
    awful.key({ MOD,           }, "t",      function (c) c.ontop = not c.ontop            end, {description = "toggle keep on top", group = "client"}),
    awful.key({ MOD,           }, "n", function (c) c.minimized = true end , {description = "minimize", group = "client"}),
    awful.key({ MOD,           }, "q", function (c) c:kill()                        end, {description = "kill focused client",                group = "client"}),
    awful.key({ MOD,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ MOD, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ MOD, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    KEYS = gears.table.join(KEYS,
        -- View tag only.
        awful.key({ MOD }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ MOD, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ MOD, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ MOD, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ MOD }, 1, awful.mouse.client.move),
    awful.button({ MOD }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(KEYS)
-- }}}
-- 5. Rules {{{
-- TODO: Import from external file.
awful.rules.rules = {
    -- DEFAULT
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = CLIENT_KEYS,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},
    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "dialog" } }, properties = { titlebars_enabled = true } },

    -- Workspace
    { rule = { class = "Firefox" }, properties = { screen = 1, tag = "2" } },
    { rule = { class = "Spotify" }, properties = { screen = 1, tag = "9" } },
    -- Chat
    { rule = { class = "Keybase" }, properties = { screen = 2, tag = "3" } },
    { rule = { class = "Slack" }, properties = { screen = 2, tag = "3" } },

    -- VM sessions go on second screen
    { rule = { class = "virt-manager" }, properties = { screen = 2, tag = "1" } },
    { rule = { name = "win10 on QEMU/KVM" }, properties = { screen = 2, tag = "2" } },
}
-- }}}
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
-- }}}
-- vim:foldmethod=marker:foldlevel=0
