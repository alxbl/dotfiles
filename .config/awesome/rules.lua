local beautiful = require("beautiful")
local awful     = require("awful")
local keys      = require("keys")

awful.rules.rules = {
    -- DEFAULT
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = keys.client,
            buttons = keys.client_buttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen
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

    -- Add titlebars to dialogs.
    { rule_any = {type = { "dialog" } }, properties = { titlebars_enabled = true } },

    -- Workspace
    { rule = { class = "Firefox" }, properties = { screen = 1, tag = "2" } },
    { rule = { class = "Emacs" },   properties = { screen = 1, tag = "1" } },
    { rule = { class = "Termite" }, properties = { screen = 1, tag = "1" } },
    { rule = { class = "Spotify" }, properties = { screen = 1, tag = "9" } },
    -- Chat
    { rule = { class = "Keybase" }, properties = { screen = 2, tag = "3" } },
    { rule = { class = "Slack" },   properties = { screen = 2, tag = "3" } },

    -- VM sessions go on second screen
    { rule = { class = "virt-manager" },     properties = { screen = 2, tag = "1" } },
    { rule = { name = "win10 on QEMU/KVM" }, properties = { screen = 2, tag = "2" } },
}

return awful.rules.rules
