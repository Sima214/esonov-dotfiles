-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
require("naughty.dbus")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget

-----------------------------------------------------------------
-- Basic setup to help with debugging.
local function debug_error(err)
  local msg = tostring(err)
  print(err)
  naughty.notify({preset = naughty.config.presets.critical, timeout = 4, title = awesome.startup and "An error occured on startup." or "An error occured.", text = msg})
end

function print(...)
  local msg = table.concat(table.pack(...), " ")
  io.stderr:write(msg)
  io.stderr:write("\n")
  io.stderr:flush()
end

-- Handle runtime errors.
awesome.connect_signal("debug::error", debug_error)

-----------------------------------------------------------------
-- Helper (global) functions.
-- Converts an awesome client object to a debug string.
function client2string(c)
  local t = {"id="..tostring(c.window), "name="..tostring(c.name), "type="..tostring(c.type), "class="..tostring(c.class), "instance="..tostring(c.instance), "icon="..tostring(c.icon_name)}
  return "{"..table.concat(t, ", ").."}"
end

-- Load a properties file.
function load_prop(filename)
  local f, msg = io.open(filename, "r")
  if f then
    local s = f:read("*all")
    s = "return {"..s:gsub("\n", ", ").."}"
    local c, msg = load(s, filename, "t", {})
    if c then
      local a, b = pcall(c)
      if a then
        return b
      else
        return nil, b
      end
    else
      return nil, msg
    end
  else
    return nil, msg
  end
end

-----------------------------------------------------------------
-- Execute static configuration code.
assert(loadfile(gears.filesystem.get_configuration_dir().."static.lua"))()

-- Configure the bars.
assert(loadfile(gears.filesystem.get_configuration_dir().."bar.lua"))()

-- Setup keybinds.
assert(loadfile(gears.filesystem.get_configuration_dir().."keys.lua"))()