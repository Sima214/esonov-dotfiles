local api = {}

-- WM libs.
local awful = require("awful")
local spawn = awful.spawn.spawn
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
-- Native libs.
local cairo = require("lgi").cairo
-- Helpers.
local clients = require("clients")
-- Extra libs.
local lfs = assert(require("lfs"), "Please install Linux File System!")

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
colors_inactive["0000ff"] = "#292089"
local colors_highlight = {}
colors_highlight["000000"] = "#2e293a"
colors_highlight["ffffff"] = "#cac8d1"
colors_highlight["ff0000"] = "#2a00c1"
colors_highlight["00ff00"] = "#2a00c1"
colors_highlight["0000ff"] = "#4629bb"
-- Internal state.
local tag_registry = {}

-- Private functions.
local function svg_scaled_surface(name, data, revision, width, height)
  lfs.mkdir(icons_path.."cache")
  local cache_code = string.format("%s_%ix%i_%s", tostring(revision), width, height, name)
  local cache_fn = "cache/"..cache_code..".png"
  local final_surface = nil
  -- Check if icon is not cached.
  if lfs.attributes(icons_path..cache_fn, "mode")~="file" then
    -- png conversion
    local converter = io.popen(string.format("inkscape -z -e %s -w %i -h %i /dev/stdin", icons_path..cache_fn, width, height), "w")
    converter:write(data)
    if not converter:close() then
      return nil, "Conversion failed."
    end
  end
  -- png file to surface
  final_surface = cairo.ImageSurface.create_from_png(icons_path..cache_fn)
  if is_surface_valid(final_surface) then
    return final_surface
  else
    return nil, "Could not load surface: "..final_surface.status
  end
end

local function generate_icon_set(is, as, hs)
  local icon_size = ICON_SIZE+PADDING*2
  local final_set = {}
  -- 0. Generate outline/halo.
  local halo = cairo.ImageSurface.create(cairo.Format.ARGB32, icon_size, icon_size)
  local cr = cairo.Context.create(halo)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:scale(1.08, 1.08)
  cr:mask_surface(is, 1, 1)
  -- 1. Generate inactive icon.
  final_set.inactive = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.inactive)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(is, 1, 1)
  cr:paint()
  return final_set
end

local function preload_resources()
  print("Generating tag icons...")
  for _, tag in ipairs(tag_registry) do
    local i, msg = io.open(icons_path..tag.icon, "r")
    if i then
      local base_icon = i:read("*all")
      i:close()
      local revision = lfs.attributes(icons_path..tag.icon, "modification")
      local inactive = base_icon:gsub("#(%x%x%x%x%x%x)", colors_inactive)
      local active = base_icon:gsub("#(%x%x%x%x%x%x)", colors_active)
      local highlight = base_icon:gsub("#(%x%x%x%x%x%x)", colors_highlight)
      -- These methods must succeed for the program to function.
      local inactive_surface = assert(svg_scaled_surface("inactive_"..tag.name ,inactive, revision, ICON_SIZE, ICON_SIZE))
      local active_surface = assert(svg_scaled_surface("active_"..tag.name ,active, revision, ICON_SIZE, ICON_SIZE))
      local highlight_surface = assert(svg_scaled_surface("highlight_"..tag.name, highlight, revision, ICON_SIZE, ICON_SIZE))
      tag.icon_set = generate_icon_set(inactive_surface, active_surface, highlight_surface)
    else
      print("Could not load icon "..tag.icon..". "..msg)
    end
    print("Loaded icons for: "..tag.name)
  end
end

-- ct constains wibox, drawable, dpi and screen.
-- cr is the cairo context.
local function render_tag(self, ct, cr, w, h)
  -- First prepare the cairo context.
  for i, tag in ipairs(tag_registry) do
    -- Calculate destination offset.
    local offset = (i-1)*(PADDING*2+ICON_SIZE+EXTRA_HORIZONTAL_SPACING)
    -- Paint the right surface.
    cr:set_source_surface(tag.icon_set.inactive, offset, 0)
    cr:paint()
  end
end

-- Client grabbing state.
local waiting_for_id = nil
local waiting_tag_index = nil

-- Handlers for finishing up spawn events.
local function handle_client_ready(args)
  print(args.id, waiting_for_id)
  if args.id==waiting_for_id then
    -- That tag that was selected.
    local selected = tag_registry[waiting_tag_index]
    if type(selected.waiting)=="number" then
      local next_index = selected.waiting + 1
      -- Check if next index exists.
      if selected.spawn_cmd[next_index] then
        local pid, id = spawn(selected.spawn_cmd[next_index], true)
        if type(pid)=="number" then
          selected.waiting = next_index
          waiting_for_id = id
          waiting_tag_index = selected.index
          print(string.format("Tag %s waiting for %s (pid: %i) on id %s [%i/%i]", selected.name, selected.spawn_cmd[next_index], pid, id, next_index, #selected.spawn_cmd))
        else
          -- Spawn errored. Error message is stored in pid.
          print("Could not spawn \""..selected.spawn_cmd.."\": "..pid)
        end
      else
        -- Finish up.
        selected.waiting = false
        selected.instance:view_only()
        waiting_for_id = nil
        waiting_tag_index = nil
        print(args.id.." spawned successfully.")
      end
    else
      selected.waiting = false
      selected.instance:view_only()
      waiting_for_id = nil
      waiting_tag_index = nil
      print(args.id.." spawned successfully.")
    end
  end
end
local function handle_client_failed(args)
  if args.id==waiting_for_id then
    waiting_for_id = nil
    waiting_tag_index = nil
    print("For some reason spawn "..args.id.." failed to start.")
  end
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
  -- Setup clients.
  clients.setup(tag_registry)
end

function api.gen_widget(scr)
  -- Preload resources required for rendering the widget.
  preload_resources()
  -- Define the widget.
  local wtl = wibox.widget.base.make_widget()
  wtl.draw = render_tag
  -- Size calculation.
  function wtl:fit(c, w, h)
    -- Calculate size.
    local l = #tag_registry
    local h = ICON_SIZE + PADDING*2
    local w = h*l + EXTRA_HORIZONTAL_SPACING*(l-1)
    return w, h
  end
  return wtl
end

function api.select_tag(tag_id)
  local selected = tag_registry[tag_id]
  local tag = selected.instance
  -- Test if tag has any clients.
  if #tag:clients() ~= 0 then
    -- If it has then switch to it.
    selected.waiting = false
    tag:view_only()
  elseif selected.waiting then
    print("Please be patient...")
  elseif selected.spawn_cmd and #selected.spawn_cmd~=0 then
    -- Else start the default program(if any) and switch to it when window is ready.
    if type(selected.spawn_cmd)=="table" then
      local pid, id = spawn(selected.spawn_cmd[1], true)
      if type(pid)=="number" then
        waiting_for_id = id
        waiting_tag_index = selected.index
        selected.waiting = 1
        print(string.format("Tag %s waiting for %s (pid: %i) on id %s [%i/%i]", selected.name, selected.spawn_cmd[1], pid, id, 1, #selected.spawn_cmd))
      else
        -- Spawn errored. Error message is stored in pid.
        print("Could not spawn \""..selected.spawn_cmd.."\": "..pid)
      end
    else
      local pid, id = spawn(selected.spawn_cmd, true)
      if type(pid)=="number" then
        waiting_for_id = id
        waiting_tag_index = selected.index
        selected.waiting = true
        print(string.format("Tag %s waiting for %s (pid: %i) on id %s", selected.name, selected.spawn_cmd, pid, id))
      else
        -- Spawn errored. Error message is stored in pid.
        print("Could not spawn \""..selected.spawn_cmd.."\": "..pid)
      end
    end
  else
    -- There is nothing else to do, so just log this.
    print("Tried selecting tag "..selected.name.." but it's empty.")
  end
end

function api.register_buttons(keyboard, mousekey)
  -- Register keyboard shortcuts.
  for _, obj in ipairs(tag_registry) do
    local new_key = awful.key({modkey}, obj.key, function() api.select_tag(obj.index) end)
    keyboard = gears.table.join(keyboard, new_key)
  end
  -- Register general handlers.
  awesome.connect_signal("spawn::completed", handle_client_ready)
  awesome.connect_signal("spawn::canceled", handle_client_failed)
  awesome.connect_signal("spawn::timeout", handle_client_failed)
  -- Return new bindings.
  return keyboard, mousekey
end

return api