-- Load basic awesome libs.
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
-- Widgets
local wibox = require("wibox")
-- Theme library.
local beautiful = require("beautiful")

-- Print generic information.
print("Awesome "..awesome.version, "(".._VERSION..")")
print("Config path: "..gears.filesystem.get_configuration_dir())
print("Theme path:", awesome.themes_path)
print("Icons path:", awesome.icon_path)

-- Constants
terminal = "kitty -1"
editor = "vim"
editor_cmd = "kitty -e vim"
modkey = "Mod4"
conf_path = gears.filesystem.get_configuration_dir()
icons_path = conf_path.."/icons/"
tags_path = conf_path.."/tags/"

-- Setup the look and feel.
beautiful.init(gears.filesystem.get_configuration_dir().."/theme.lua")
gears.wallpaper.set("#000000")
awesome.set_preferred_icon_size(48)
-- Lock layout to floating, as we are using a custom solution.
awful.layout.layouts = { awful.layout.suit.floating }

-- Setup default applications.
menubar.utils.terminal = terminal