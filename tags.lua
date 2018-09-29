local api = {}

-- Libraries.
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local lfs = assert(require("lfs"))
-- Native libs.
local pixbuf = require("lgi").GdkPixbuf

-- Settings
local ICON_SIZE = 24
local PADDING = 1
local EXTRA_HORIZONTAL_SPACING = 8                       
local cache_path = icons_path.."cache/"

-- Lookup tables.
local LAYOUT_STR2OBJ = {
                        float = awful.layout.suit,
                        magnifier = awful.layout.suit.magnifier,
                        max = awful.layout.suit.max,
                        fullscreen = awful.layout.suit.max.fullscreen,
                        dwindle = awful.layout.suit.spiral.dwindle,
                        spiral = awful.layout.suit.spiral
                       }
local dark_color = "#2e293a"
local light_color = "#cac8d1"
local highlight_color = "#481565"
local highlight_alt_color = "#481565"
local colors_inactive = {}
-- Same as the background.
colors_inactive["000000"] = "#2e293a"
-- The base color.
colors_inactive["ffffff"] = "#8c80a4"
-- Highlight color pattern #1.
-- It is invisible when inactive, and pulsating when urgent.
colors_inactive["ff0000"] = "#2e293a"
-- Highlight color pattern #2.
-- Visible even when inactive, but darker.
colors_inactive["00ff00"] = "#292089"
-- Highlight color pattern #3.
-- Constant color(may add blur when urgent), just a bit darker when inactive.
colors_inactive["0000ff"] = "#292089"
local colors_active = {}
colors_active["000000"] = "#2e293a"
colors_active["ffffff"] = "#cac8d1"
colors_active["ff0000"] = "#4629bb"
colors_active["00ff00"] = "#4629bb"
colors_active["0000ff"] = "#4629bb"

-- Internal state.
local tag_registry = {}

-- Private functions.
local svg_surface_scaled_tmp_file = os.tmpname()
local function svg_scaled_surface(data, width, height)
  -- Could not make the pixbug loader work.
  local f = io.open(svg_surface_scaled_tmp_file, "w")
  f:write(data)
  f:close()
  local s, msg = awesome.load_image(svg_surface_scaled_tmp_file)
  os.remove(svg_surface_scaled_tmp_file)
  return s, msg
end

local function preload_resources()
  print("Generating tag icons...")
  for _, tag in ipairs(tag_registry) do
    local i, msg = io.open(icons_path..tag.icon, "r")
    if i then
      local base_icon = i:read("*all")
      i:close()
      local inactive = base_icon:gsub("#(%x%x%x%x%x%x)", colors_inactive)
      assert(svg_scaled_surface(inactive))
      local active = base_icon:gsub("#(%x%x%x%x%x%x)", colors_active)
    else
      print("Could not load icon "..tag.icon..". "..msg)
    end
    print("Generated icons for: "..tag.name)
  end
end

local function render_tag(self, ct, cr, w, h)
end

-- Api.
function api.init(scr)
  print("Registering tags...")
  for fn in lfs.dir(tags_path) do
    if fn:find("%.properties") then
      local name = fn:match("([^/]+)%.properties")
      local obj, msg = load_prop(tags_path..fn)
      if obj and obj.index then
        obj.name = name
        if obj.layout then
          local new = LAYOUT_STR2OBJ[obj.layout]
          if not new then
            print("Unknown layout "..obj.layout)
            obj.layout = awful.layout.suit
          else
            obj.layout = new
          end
        else
          -- If no layout is set, then set a default one.
          obj.layout = awful.layout.suit
        end
        -- Finalize registration.
        tag_registry[obj.index] = obj
        tag_registry[name] = obj
        print("Registered "..name)
      else
        print("Error loading tag "..name..": "..msg)
      end
    end
  end
  -- Inform awesome about the new tags.
  for _, obj in ipairs(tag_registry) do
    args = {index = obj.index, screen = scr, layout = obj.layout,
            gap = obj.gap, icon = icons_path..obj.icon}
    obj.instance = awful.tag.add(obj.name, args)
  end
  tag_registry[1].instance.selected = true
end

function api.gen_widget(scr)
  -- Preload resources required for rendering the widget.
  preload_resources()
  -- Define the widget.
  local wtl = wibox.widget.base.make_widget()
  wtl.draw = render_tag
  -- Size calculation.
  function wtl:fit(c, w, h)
    -- Calculate size from 
    local l = #tag_registry
    local h = ICON_SIZE + PADDING*2
    local w = h*l + EXTRA_HORIZONTAL_SPACING*(l-1)
    return w, h
  end
  return wtl
end

function api.register_buttons()
end

return api