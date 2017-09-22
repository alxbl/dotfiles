local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local ipairs, string, os, table, tostring, tonumber, type = ipairs, string, os, table, tostring, tonumber, type
local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
local CONFIG_DIR = string.format("%s/.config/awesome/", os.getenv("HOME"))
local VARS = gears.protected_call(dofile, CONFIG_DIR .. "vars.lua")
local KEYMAP = require("keymap")
local RULES = require("rules")

-- {{{ Error handling
if awesome.startup_errors then naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart windowless processes
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

run_once({ "unclutter -root" }) -- entries must be comma-separated
-- }}}

awful.util.terminal = VARS.terminal
awful.util.tagnames = { "DEV", "WEB", "DOC", "COM" }
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    lain.layout.cascade,
    lain.layout.cascade.tile,
    lain.layout.centerwork,
    lain.layout.termfair.center,
}

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

-- TODO: themes_dir()
local theme_path = string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), VARS.chosen_theme)
beautiful.init(theme_path)

local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", VARS.terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", VARS.terminal, VARS.editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or 16,
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", VARS.terminal },
        -- other triads can be put here
    }
})
-- {{{ Screen
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    KEYMAP,
    -- On the fly useless gaps change
    awful.key({ VARS.altkey, "Control" }, "+", function () lain.util.useless_gaps_resize(1) end),
    awful.key({ VARS.altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end),

    -- Dynamic tagging
    awful.key({ VARS.modkey, "Shift" }, "n", function () lain.util.add_tag() end),
    awful.key({ VARS.modkey, "Shift" }, "r", function () lain.util.rename_tag() end),
    awful.key({ VARS.modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end),  -- move to previous tag
    awful.key({ VARS.modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end),  -- move to next tag
    awful.key({ VARS.modkey, "Shift" }, "d", function () lain.util.delete_tag() end),

    -- Standard program
    awful.key({ VARS.altkey, "Shift" }, "l", function () awful.tag.incmwfact( 0.05) end, {description = "increase master width factor", group = "layout"}),
    awful.key({ VARS.altkey, "Shift" }, "h", function () awful.tag.incmwfact(-0.05) end, {description = "decrease master width factor", group = "layout"}),
    awful.key({ VARS.modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1, nil, true) end, {description = "increase the number of master clients", group = "layout"}),
    awful.key({ VARS.modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1, nil, true) end, {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ VARS.modkey, "Control" }, "h", function () awful.tag.incncol( 1, nil, true) end, {description = "increase the number of columns", group = "layout"}),
    awful.key({ VARS.modkey, "Control" }, "l", function () awful.tag.incncol(-1, nil, true) end, {description = "decrease the number of columns", group = "layout"}),
    awful.key({ VARS.modkey}, "space", function () awful.layout.inc( 1) end, {description = "select next", group = "layout"}),
    awful.key({ VARS.modkey, "Shift"   }, "space", function () awful.layout.inc(-1) end, {description = "select previous", group = "layout"}),

    awful.key({ VARS.modkey, "Control" }, "n", function ()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
            client.focus = c
            c:raise()
        end
    end, {description = "restore minimized", group = "client"}),

    -- Dropdown application
    awful.key({ VARS.modkey, }, "z", function () awful.screen.focused().quake:toggle() end),
    
    -- Copy primary to clipboard (terminals to gtk)
    awful.key({ VARS.modkey }, "c", function () awful.spawn("xsel | xsel -i -b") end),
    -- Copy clipboard to primary (gtk to terminals)
    awful.key({ VARS.modkey }, "v", function () awful.spawn("xsel -b | xsel") end),

    -- User programs
    awful.key({ VARS.modkey }, "q", function () awful.spawn(VARS.browser) end),
    awful.key({ VARS.modkey }, "a", function () awful.spawn(VARS.guieditor) end)
)

clientkeys = awful.util.table.join(
    awful.key({ VARS.altkey, "Shift"   }, "m",      lain.util.magnify_client                         ),
    awful.key({ VARS.modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ VARS.modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ VARS.modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ VARS.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ VARS.modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ VARS.modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ VARS.modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ VARS.modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ VARS.modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ VARS.modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ VARS.modkey, "Shift" }, "#" .. i + 9,
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
        awful.key({ VARS.modkey, "Control", "Shift" }, "#" .. i + 9,
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

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ VARS.modkey }, 1, awful.mouse.client.move),
    awful.button({ VARS.modkey }, 3, awful.mouse.client.resize))

-- Set keys
-- Always bind the core shortcuts in rc.lua to ensure they are available.
globalkeys = awful.util.table.join(globalkeys,
    awful.key({ VARS.modkey }, "s", hotkeys_popup.show_help, {description="show help", group="awesome"}),
    awful.key({ VARS.modkey }, "Return", function () awful.spawn(VARS.terminal) end, {description = "open a terminal", group = "launcher"}),
    awful.key({ VARS.modkey, "Control" }, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({ VARS.modkey, "Shift"   }, "q", awesome.quit, {description = "quit awesome", group = "awesome"}),
    awful.key({ VARS.modkey }, "r", function () awful.screen.focused().mypromptbox:run() end, {description = "run prompt", group = "launcher"}),
    awful.key({ VARS.modkey }, "x", function ()
        awful.prompt.run {
        prompt       = "Run Lua code: ",
        textbox      = awful.screen.focused().mypromptbox.widget,
        exe_callback = awful.util.eval,
        history_path = awful.util.get_cache_dir() .. "/history_eval"
        }
    end, {description = "lua execute prompt", group = "awesome"})
)


root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     }
    },

    -- Titlebars
    { rule_any = { type = { "dialog", "normal" } },
      properties = { titlebars_enabled = true } },

    -- Set Firefox to always map on the first tag on screen 1.
    { rule = { class = "Firefox" },
      properties = { screen = 1, tag = awful.util.tagnames[1] } },

    { rule = { class = "Gimp", role = "gimp-image-window" },
          properties = { maximized = true } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
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

    awful.titlebar(c, {size = 32}) : setup {
        {
            layout = wibox.layout.fixed.horizontal()
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--     if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
--         and awful.client.focus.filter(c) then
--         client.focus = c
--     end
-- end)

-- No border for maximized clients
client.connect_signal("focus",
    function(c)
        if c.maximized then -- no borders if only 1 client visible
            c.border_width = 0
        elseif #awful.screen.focused().clients > 1 then
            c.border_width = beautiful.border_width
            c.border_color = beautiful.border_focus
        end
    end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
