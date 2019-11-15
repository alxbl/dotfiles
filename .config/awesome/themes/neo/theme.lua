local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local settings = require("settings")
local dpi = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local theme = {}

theme.font = "Noto sans"

local accent = "#6272a4"
local dark =   "#282a36"
local foreground = "#f8f8f2"

theme.bg_normal     = dark
-- theme.bg_focus      = "#535d6c"
theme.bg_focus      = accent
theme.bg_urgent     = "#ff5555"
theme.bg_minimize   = "#444444"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = foreground
theme.fg_focus      = foreground
theme.fg_urgent     = foreground
theme.fg_minimize   = theme.fg_normal

theme.useless_gap   = dpi(4)
theme.border_width  = 1
theme.border_normal = "#282a36"
theme.border_focus  = accent -- "#bd93f9"
theme.border_marked = "#f1fa8c"
theme.wallpaper = settings.HOME .. "/.config/awesome/wall.png"
theme.tasklist_bg_focus = dark -- No accent on active task

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(taglist_square_size, theme.fg_normal)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(taglist_square_size, theme.fg_normal)

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

theme.lain_icons         = settings.HOME ..  "/.config/awesome/lain/icons/layout/default/"
theme.layout_termfair    = theme.lain_icons .. "termfair.png"
theme.layout_centerfair  = theme.lain_icons .. "centerfair.png"  -- termfair.center
theme.layout_cascade     = theme.lain_icons .. "cascade.png"
theme.layout_cascadetile = theme.lain_icons .. "cascadetile.png" -- cascade.tile
theme.layout_centerwork  = theme.lain_icons .. "centerwork.png"
theme.layout_centerworkh = theme.lain_icons .. "centerworkh.png" -- centerwork.horizontal
theme.layout_fairh       = themes_path      .. "default/layouts/fairhw.png"
theme.layout_fairv       = themes_path      .. "default/layouts/fairvw.png"

theme.layout_floating   = themes_path .. "default/layouts/floatingw.png"
theme.layout_magnifier  = themes_path .. "default/layouts/magnifierw.png"
theme.layout_max        = themes_path .. "default/layouts/maxw.png"
theme.layout_fullscreen = themes_path .. "default/layouts/fullscreenw.png"
theme.layout_tilebottom = themes_path .. "default/layouts/tilebottomw.png"
theme.layout_tileleft   = themes_path .. "default/layouts/tileleftw.png"
theme.layout_tile       = themes_path .. "default/layouts/tilew.png"
theme.layout_tiletop    = themes_path .. "default/layouts/tiletopw.png"
theme.layout_spiral     = themes_path .. "default/layouts/spiralw.png"
theme.layout_dwindle    = themes_path .. "default/layouts/dwindlew.png"
theme.layout_cornernw   = themes_path .. "default/layouts/cornernww.png"
theme.layout_cornerne   = themes_path .. "default/layouts/cornernew.png"
theme.layout_cornersw   = themes_path .. "default/layouts/cornersww.png"
theme.layout_cornerse   = themes_path .. "default/layouts/cornersew.png"

return theme
