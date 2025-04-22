-- Load basic awesome libs.
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
-- Widgets
local wibox = require("wibox")
-- Theme library.
local beautiful = require("beautiful")

-- Which one of my machines are we currently running on?
machine_identifier = read_secret(gears.filesystem.get_configuration_dir().."machine_identifier")

-- Constants
terminal = "kitty -1"
editor = "vim"
editor_cmd = "kitty -e vim"
modkey = "Mod4"
conf_path = gears.filesystem.get_configuration_dir()
icons_path = conf_path.."/icons/"
icons_cache_path = icons_path.."cache/"
tags_path = conf_path.."/tags/"
tags_spawn_timeout_sec = 30
tasklist_height = 12
if machine_identifier == "laptop" then
  screenshot_output = "/home/sima/local/media/memories/"
else
  screenshot_output = "/home/sima/storage/akashi/nvmedia/memories"
end

-- Setup the look and feel.
beautiful.init(conf_path.."/theme.lua")
awesome.set_preferred_icon_size(24)
-- Lock layout to floating, as we are using a custom solution.
awful.layout.layouts = { awful.layout.suit.floating }

-- Setup default applications.
menubar.utils.terminal = terminal

-- Load weather config.
weather_config = {
  endpoint = "http://api.openweathermap.org/data/2.5/weather",
  api_key = read_secret(gears.filesystem.get_configuration_dir().."openweathermap.key"),
  city_id = 734077,
  units = "metric",
  update_interval = 1800 -- In seconds
}

-- Print generic information.
print("Awesome "..awesome.version.." (".._VERSION..")")
if awesome.composite_manager_running then
  print("Composite manager detected!")
else
  print("No composite manager detected!")
end
print("Config path: "..conf_path)
print("Theme path: "..awesome.themes_path)
print("Icons path: "..awesome.icon_path)
print("Machine identifier: "..machine_identifier)

-- Initialize RNG
math.randomseed(os.time())