local awful = require("awful")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")

local utils    = require("utils")
local settings = require("settings")

local MOD = settings.keys.super
local ALT = settings.keys.alt
local CTL = settings.keys.ctrl
local SFT = settings.keys.shift

local keys = {}


keys.taglist = gears.table.join(
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

keys.taskbar = gears.table.join(
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


root.keys(keys.globalkeys)
root.buttons(keys.desktopbuttons)
return keys
