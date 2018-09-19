local api = {}

-- Libraries.
local awful = require("awful")
local lfs = assert(require("lfs"))

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
  local function on_click_tag(t)
    t:view_only()
  end
  return awful.widget.taglist(scr, awful.widget.taglist.filter.all, awful.button({ }, 1, on_click_tag))
end

function api.register_buttons()
end

return api