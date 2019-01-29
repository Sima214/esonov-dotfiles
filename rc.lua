-- Standard awesome library
local gears = require("gears")
-- Notification library
local naughty = require("naughty")
require("naughty.dbus")
-- Native libs.
local cairo = require("lgi").cairo
-- Globals.
AFTER_INIT = {}

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

-- Check if a cairo surface is valid.
function is_surface_valid(s)
  if s.status == "SUCCESS" then
    return true
  else
    return false, s.status
  end
end

-- theme color to cairo rgb
function color2rgb(color)
  local r, g, b = 0.0, 0.0, 0.0
  local rgb = tonumber("0x"..color:match("#(%x+)"))
  b = (rgb&0xff)/0xff
  rgb = rgb>>8
  g = (rgb&0xff)/0xff
  rgb = rgb>>8
  r = (rgb&0xff)/0xff
  return r, g, b
end

-- Create an empty file (touch).
function touch(filename)
  return os.execute("touch "..filename)
end

-----------------------------------------------------------------
-- Execute static configuration code.
assert(loadfile(gears.filesystem.get_configuration_dir().."static.lua"))()

-- Configure the bars.
assert(loadfile(gears.filesystem.get_configuration_dir().."bar.lua"))()

-- Setup keybinds.
assert(loadfile(gears.filesystem.get_configuration_dir().."keys.lua"))()

-- Perform any actions deffered after initialization.
awesome.connect_signal("startup", function() for _, action in ipairs(AFTER_INIT) do action() end end)