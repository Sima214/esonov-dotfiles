-- Standard awesome libraries
local gears = require("gears")
-- Notification library
local naughty = require("naughty")
require("naughty.dbus")
-- External libraries.
local lfs = assert(require("lfs"), "Please install Lua File System!")

-- Globals.
old_print = print

-----------------------------------------------------------------
-- Basic setup to help with debugging.
local function debug_error(err)
  local msg = tostring(err)
  print(err)
  naughty.notify({preset = naughty.config.presets.critical, timeout = 4, title = awesome.startup and "An error occured on startup." or "An error occured.", text = msg})
end

function print(...)
  local t = table.pack(...)
  local msg = table.concat(t)
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

-- Check if a cairo surface is valid.
function is_surface_valid(s)
  if s.status == "SUCCESS" then
    return true
  else
    return false, s.status
  end
end

-- theme color(hex) to cairo rgb(a) tuple
function color2rgb(color)
  local r, g, b
  local rgb = tonumber(color:sub(2), 16)
  b = (rgb & 0xff) / 0xff
  rgb = rgb >> 8
  g = (rgb & 0xff) / 0xff
  rgb = rgb >> 8
  r = (rgb & 0xff) / 0xff
  return r, g, b
end
function color2rgba(color)
  local r, g, b, a
  local rgba = tonumber(color:sub(2), 16)
  a = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  b = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  g = (rgba & 0xff) / 0xff
  rgba = rgba >> 8
  r = (rgba & 0xff) / 0xff
  return r, g, b, a
end

-- Create an empty file (touch).
function touch(filename)
  return lfs.touch(filename)
end

-----------------------------------------------------------------

-- Execute static configuration code.
assert(loadfile(gears.filesystem.get_configuration_dir().."static.lua"))()

-- Configure the bars.
assert(loadfile(gears.filesystem.get_configuration_dir().."bar.lua"))()

-- Setup keybinds.
assert(loadfile(gears.filesystem.get_configuration_dir().."keys.lua"))()

--[[
  TODO:
    clipboard manager,
    novideo switcher,
    tag spawn chooser,
    tasklist no special characters and no bottom character cutting,
    volume bar,
--]]