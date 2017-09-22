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

-- -----------------------------------------------------------------------------
-- Base layout key bindings
-- -----------------------------------------------------------------------------
local CONFIG_DIR = string.format("%s/.config/awesome/", os.getenv("HOME"))
local VARS = gears.protected_call(dofile, CONFIG_DIR .. "vars.lua")

-- Functions
local function move_to_tag(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end

local function toggle_tag(t)
    if client.focus then
        client.focus:toggle_tag(t)
    end
end

local function toggle_client(c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() and c.first_tag then
            c.first_tag:view_only()
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end

local function toggle_client_list()
    local instance = nil
    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

local function toggle_menu()
end

-- ROOT: Mouse buttons
root.buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.util.mymainmenu:hide() end),
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- TAG LIST: Mouse buttons
awful.util.taglist_buttons = awful.util.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ VARS.modkey }, 1, move_to_tag),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ VARS.modkey }, 3, toggle_tag),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- TASK LIST: Mouse buttons
awful.util.tasklist_buttons = awful.util.table.join(
    awful.button({ }, 1, toggle_client),
    awful.button({ }, 3, toggle_client_list),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

-- KEYBOARD SHORTCUTS.
local bindings = awful.util.table.join(
    -- Tag browsing
    awful.key({ VARS.modkey }, "Left", awful.tag.viewprev, {description = "view previous", group = "tag"}),
    awful.key({ VARS.modkey }, "Right",  awful.tag.viewnext, {description = "view next", group = "tag"}),
    awful.key({ VARS.modkey }, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),
    -- Non-empty tag browsing
    awful.key({ VARS.altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end, {description = "view  previous nonempty", group = "tag"}),
    awful.key({ VARS.altkey }, "Right", function () lain.util.tag_view_nonempty(1) end, {description = "view  previous nonempty", group = "tag"}),
    -- Default client focus
    awful.key({ VARS.altkey }, "j", function () awful.client.focus.byidx( 1) end, {description = "focus next by index", group = "client"}),
    awful.key({ VARS.altkey }, "k", function () awful.client.focus.byidx(-1) end, {description = "focus previous by index", group = "client"}),
    -- By direction client focus
    awful.key({ VARS.modkey }, "j", function() awful.client.focus.bydirection("down") if client.focus then client.focus:raise() end end),
    awful.key({ VARS.modkey }, "k", function() awful.client.focus.bydirection("up") if client.focus then client.focus:raise() end end),
    awful.key({ VARS.modkey }, "h", function() awful.client.focus.bydirection("left") if client.focus then client.focus:raise() end end),
    awful.key({ VARS.modkey }, "l", function() awful.client.focus.bydirection("right") if client.focus then client.focus:raise() end end),
    awful.key({ VARS.modkey }, "w", function () awful.util.mymainmenu:show() end, {description = "show main menu", group = "awesome"}),
    -- Layout manipulation
    awful.key({ VARS.modkey, "Shift" }, "j", function () awful.client.swap.byidx(  1) end, {description = "swap with next client by index", group = "client"}),
    awful.key({ VARS.modkey, "Shift" }, "k", function () awful.client.swap.byidx( -1) end, {description = "swap with previous client by index", group = "client"}),
    awful.key({ VARS.modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end, {description = "focus the next screen", group = "screen"}),
    awful.key({ VARS.modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end, {description = "focus the previous screen", group = "screen"}),
    awful.key({ VARS.modkey }, "u", awful.client.urgent.jumpto, {description = "jump to urgent client", group = "client"}),
    awful.key({ VARS.modkey }, "Tab", function () awful.client.focus.history.previous() if client.focus then client.focus:raise() end end, {description = "go back", group = "client"}),

    -- Show/Hide Wibox
    awful.key({ VARS.modkey }, "b", function ()
        for s in screen do
            s.mywibox.visible = not s.mywibox.visible
            if s.mybottomwibox then
                s.mybottomwibox.visible = not s.mybottomwibox.visible
            end
        end
    end)
)

--
return bindings
