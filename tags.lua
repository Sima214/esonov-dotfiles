local api = {}

-- Libraries.
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local lfs = assert(require("lfs"))

-- Settings
local ICON_SIZE = 24
local PADDING = 2
local EXTRA_HORIZONTAL_SPACING = 8
-- Lookup tables.
local LAYOUT_STR2OBJ = {
                        float = awful.layout.suit,
                        magnifier = awful.layout.suit.magnifier,
                        max = awful.layout.suit.max,
                        fullscreen = awful.layout.suit.max.fullscreen,
                        dwindle = awful.layout.suit.spiral.dwindle,
                        spiral = awful.layout.suit.spiral
                       }

-- Internal state.
local tag_registry = {}

-- Private functions.
local function preload_resources()
  print("Generating tag icons...")
  local dark_color = "#2e293a"
  local light_color = "#cac8d1"
  local highlight_color = "#481565"
  local highlight_alt_color = "#481565"
  local inactive_colors = {}
  inactive_colors["000000"] = dark_color
  inactive_colors["ffffff"] = light_color
  inactive_colors["ff0000"] = light_color
  inactive_colors["00ff00"] = light_color
  inactive_colors["0000ff"] = light_color
  local active_colors = {}
  active_colors["000000"] = dark_color
  active_colors["ffffff"] = light_color
  active_colors["ff0000"] = highlight_color
  active_colors["00ff00"] = highlight_alt_color
  active_colors["0000ff"] = highlight_color
  for _, tag in ipairs(tag_registry) do
    local i, msg = io.open(icons_path..tag.icon, "r")
    if i then
      local base_icon = i:read("*all")
      i:close()
      local inactive = base_icon:gsub("#(%x%x%x%x%x%x)", inactive_colors)
      local active = base_icon:gsub("#(%x%x%x%x%x%x)", active_colors)
      local cache_path = icons_path.."cache/"
      lfs.mkdir(cache_path)
      local finactive = io.open(cache_path.."inactive_"..tag.icon, "w")
      local factive = io.open(cache_path.."active_"..tag.icon, "w")
      finactive:write(inactive)
      finactive:close()
      factive:write(active)
      factive:close()
    else
      print("Could not load icon "..tag.icon..". "..msg)
    end
    print("Generated icons for: "..tag.name)
  end
end

-- Api.
function api.init(scr)
  for fn in lfs.dir(tags_path) do
    if fn:find("%.properties") then
      local name = fn:match("([^/]+)%.properties")
      print("Found a new tag with name \""..name.."\"")
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
        print("Successfully registered tag \""..name.."\"")
      else
        print("Error loading tag "..name..": "..msg)
      end
    end
  end
  print("Adding tags...")
  for _, o in ipairs(tag_registry) do
    args = {index = o.index, screen = scr, layout = o.layout,
            gap = o.gap, icon = icons_path..o.icon}
    o.instance = awful.tag.add(o.name, args)
    print("Added "..o.name)
  end
  tag_registry[1].instance.selected = true
  print("All tags have been added.")
end

function api.gen_widget(scr)
  local wtl = wibox.widget.base.make_widget()
  function wtl:fit(c, w, h)
    local l = #tag_registry
    local h = ICON_SIZE + PADDING*2
    local w = h*l + EXTRA_HORIZONTAL_SPACING*(l-1)
    print("Fitting #"..l.." tags.")
    return w, h
  end
  -- Preload resources.
  preload_resources()
  function wtl:draw(context, cr, w, h)
    print("Rendering taglist ("..w.."x"..h..")")
    cr:move_to(0, 0)
  end
  return wtl
  --return awful.widget.taglist(scr, awful.widget.taglist.filter.all, awful.button({ }, 1, function(t) t:view_only() end))
end

function api.register_buttons()
end

return api