local awful = require("awful")

return awful.util.table.join(
    require("keymap.layout"),
    require("keymap.mpd")
)
