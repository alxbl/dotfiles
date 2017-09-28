--
-- A simple wrapper to display an svg icon.
--
local wibox = require("wibox")
local gears = require("gears")
local lgi = require("lgi")
local cairo = lgi.cairo
local GdkPixbuf = lgi.GdkPixbuf -- rsvg instead of gdk?
local Gdk = lgi.Gdk
Gdk.init({}) -- Make sure this only gets called once?

local function factory(args) 
    
    local args = args or {}
    --
    local path = args.path
    local _, ow, oh = GdkPixbuf.Pixbuf.get_file_info(path)

    local width = args.width or ow
    local height = args.height or oh
    local color = args.color or "#000000"
    --

    local mask = Gdk.cairo_surface_create_from_pixbuf(GdkPixbuf.Pixbuf.new_from_file(path), 0, nil)
    local img = cairo.ImageSurface.create(cairo.Format.ARGB32, width, height)
    local cr = cairo.Context(img)
    cr:set_source(gears.color(color))
    cr:mask_surface(mask, 0, 0)
    cr:fill()
    
    return { widget = wibox.widget.imagebox(img) }
end

return factory
