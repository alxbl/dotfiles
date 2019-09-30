
local awful     = require("awful")
local naughty   = require("naughty")
local gears     = require("gears")
local beautiful = require("beautiful")

local hotkeys_popup = require("awful.hotkeys_popup").widget
                      require("awful.hotkeys_popup.keys")

local utils    = require("utils")
local settings = require("settings")

local MOD = settings.keys.super
local ALT = settings.keys.alt
local CTL = settings.keys.ctrl
local SFT = settings.keys.shift

local keys = {}

-- Global keys.
keys.global = gears.table.join(
    -- Core
    awful.key({ MOD,     }, "s",      hotkeys_popup.show_help, {description="show help",            group = "awesome"}),
    awful.key({ MOD, CTL }, "r",      awesome.restart,         {description = "reload awesome",     group = "awesome"}),
    awful.key({ MOD, SFT }, "q",      awesome.quit,            {description = "quit awesome",       group = "awesome"}),
    awful.key({ MOD,     }, "Return", utils.shell,             {description = "open terminal",      group = "awesome"}),
    awful.key({ MOD,     }, "Tab",    pick_wnd,                {description = "open window picker", group = "awesome"}),
    awful.key({ ALT,     }, "Tab",    pick_wnd,                {description = "open window picker", group = "awesome"}),
    awful.key({ MOD,     }, "r",      utils.run_cmd,           {description = "open launcher",      group = "awesome"}),
    awful.key({ MOD,     }, "p",      utils.screenshot,        {description = "take screenshot",    group = "awesome"}),
    awful.key({ CTL, ALT }, "l",      utils.lock_screen,       {description = "lock screen",        group = "awesome"}),

    -- TODO: Carousel
    -- awful.key({ MOD,     }, "y", function() awful.spawn("bash " .. HOME.. "/.screenlayout/laptop.sh") end, {description = "Switch to laptop",    group = "awesome"}),
    -- awful.key({ MOD,     }, "i", function() awful.spawn("bash " .. HOME .. "/.screenlayout/work-dual.sh") end, {description = "Switch to dual screen",    group = "awesome"}),

    awful.key({ MOD,     }, "Left",   awful.tag.viewprev,        {description = "view previous",  group = "tag"}),
    awful.key({ MOD,     }, "Right",  awful.tag.viewnext,        {description = "view next",      group = "tag"}),
    awful.key({ MOD,     }, "Escape", awful.tag.history.restore, {description = "go back",        group = "tag"}),

    awful.key({ MOD,     }, "l",     function() awful.tag.incmwfact( 0.05)          end, {description = "increase master width factor",          group = "layout"}),
    awful.key({ MOD,     }, "h",     function() awful.tag.incmwfact(-0.05)          end, {description = "decrease master width factor",          group = "layout"}),
    awful.key({ MOD, SFT }, "h",     function() awful.tag.incnmaster( 1, nil, true) end, {description = "increase the number of master clients", group = "layout"}),
    awful.key({ MOD, SFT }, "l",     function() awful.tag.incnmaster(-1, nil, true) end, {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ MOD, CTL }, "h",     function() awful.tag.incncol( 1, nil, true)    end, {description = "increase the number of columns",        group = "layout"}),
    awful.key({ MOD, CTL }, "l",     function() awful.tag.incncol(-1, nil, true)    end, {description = "decrease the number of columns",        group = "layout"}),
    awful.key({ MOD,     }, "space", function() awful.layout.inc( 1)                end, {description = "select next",                           group = "layout"}),
    awful.key({ MOD, SFT }, "space", function() awful.layout.inc(-1)                end, {description = "select previous",                       group = "layout"}),

    awful.key({ MOD,     }, "j", function() awful.client.focus.byidx( 1) end, {description = "focus next by index",                group = "client"}),
    awful.key({ MOD,     }, "k", function() awful.client.focus.byidx(-1) end, {description = "focus previous by index",            group = "client"}),
    awful.key({ MOD, SFT }, "j", function() awful.client.swap.byidx(  1) end, {description = "swap with next client by index",     group = "client"}),
    awful.key({ MOD, SFT }, "k", function() awful.client.swap.byidx( -1) end, {description = "swap with previous client by index", group = "client"}),
    awful.key({ MOD,     }, "u", awful.client.urgent.jumpto,                  {description = "jump to urgent client",              group = "client"}),

    -- Screens
    awful.key({ MOD, CTL }, "j", function () awful.screen.focus_relative( 1) end, {description = "focus the next screen",     group = "screen"}),
    awful.key({ MOD, CTL }, "k", function () awful.screen.focus_relative(-1) end, {description = "focus the previous screen", group = "screen"}),
    awful.key({ MOD,     }, "b", function () awful.screen.focused().taskbar.visible = not awful.screen.focused().taskbar.visible end, {description = "toggle task bar", group = "screen"}),

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


-- Bind tag management keys.
for i = 1, 9 do
    keys.global = gears.table.join(keys.global,
        awful.key({ MOD }, "#" .. i + 9, -- Go to tag.
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #" .. i, group = "tag"}),
        awful.key({ MOD, CTL }, "#" .. i + 9, -- Toggle tag.
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        awful.key({ MOD, "Shift" }, "#" .. i + 9, -- Move client to tag.
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

                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end


-- Client-specific key bindings.
keys.client = gears.table.join(
    awful.key({ MOD,     }, "f",      utils.toggle_fullscreen,                           {description = "toggle fullscreen",   group = "client"}),
    awful.key({ MOD, SFT }, "c",      function (c) c:kill()                         end, {description = "close",               group = "client"}),
    awful.key({ MOD, CTL }, "space",  awful.client.floating.toggle,                      {description = "toggle floating",     group = "client"}),
    awful.key({ MOD, CTL }, "Return", function (c) c:swap(awful.client.getmaster()) end, {description = "move to master",      group = "client"}),
    awful.key({ MOD,     }, "o",      function (c) c:move_to_screen()               end, {description = "move to screen",      group = "client"}),
    awful.key({ MOD,     }, "t",      function (c) c.ontop = not c.ontop            end, {description = "toggle keep on top",  group = "client"}),
    awful.key({ MOD,     }, "n",      function (c) c.minimized = true               end, {description = "minimize",            group = "client"}),
    awful.key({ MOD,     }, "q",      function (c) c:kill()                         end, {description = "kill focused client", group = "client"}),
    awful.key({ MOD,     }, "m",      utils.toggle_maximize,                             {description = "toggle maximize",     group = "client"})
)

-- Client mouse bindings.
keys.client_buttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ MOD }, 1, awful.mouse.client.move),
    awful.button({ MOD }, 3, awful.mouse.client.resize))

-- Taglist mouse bindings.
keys.taglist_buttons = gears.table.join(
   awful.button({ }, 1, function(t) -- View  tag.
         t:view_only()
   end), 
   awful.button({ MOD }, 1, function(t) -- Move client to tag.
         if client.focus then
            client.focus:move_to_tag(t)
         end
   end),
   awful.button({ }, 3, awful.tag.viewtoggle), -- Toggle tag.
   awful.button({ MOD }, 3, function(t) -- Toggle client focus on tag.
         if client.focus then
            client.focus:toggle_tag(t)
         end
   end),
   awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end), -- View next tag.
   awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)  -- View prev tag.
)

-- Taskbar mouse bindings.
keys.taskbar_buttons = gears.table.join(
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


-- Desktop mouse bindings.
keys.desktop = gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
)

root.keys(keys.global)
root.buttons(keys.desktop)

return keys
