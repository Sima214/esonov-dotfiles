local api = {}

-- WM libs.
local awful = require("awful")
local spawn = awful.spawn.spawn
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local screen = awful.screen
-- Native libs.
local cairo = require("lgi").cairo
-- Helpers.
local clients = require("clients")
-- Extra libs.
local lfs = assert(require("lfs"), "Please install Lua File System!")

-- Settings.
local layout = beautiful.get().tag.layout
local colors_inactive = beautiful.get().tag.colors.inactive
local colors_active = beautiful.get().tag.colors.active
local colors_highlight = beautiful.get().tag.colors.highlight

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
local function svg_scaled_surface(name, data, revision, width, height)
  lfs.mkdir(icons_cache_path)
  local cache_code = string.format("%s_%ix%i_%s", tostring(revision), width, height, name)
  local cache_fn = icons_cache_path..cache_code..".png"
  local final_surface = nil
  -- Check if icon is not cached.
  if lfs.attributes(cache_fn, "mode")~="file" then
    -- png conversion
    local converter = io.popen(string.format("inkscape -z -e %s -w %i -h %i /dev/stdin", cache_fn, width, height), "w")
    converter:write(data)
    if not converter:close() then
      return nil, "Conversion failed."
    end
  end
  -- png file to surface
  final_surface = cairo.ImageSurface.create_from_png(cache_fn)
  if is_surface_valid(final_surface) then
    return final_surface
  else
    return nil, "Could not load surface: "..final_surface.status
  end
end

local function generate_icon_set(is, as, hs)
  local icon_size = layout.icon_size + layout.padding*2
  local final_set = {selected = {hover = {}}, hover = {}}
  -- 0. Generate outline/halo.
  local halo = cairo.ImageSurface.create(cairo.Format.ARGB32, icon_size, icon_size)
  local cr = cairo.Context.create(halo)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:scale(layout.halo_scale, layout.halo_scale)
  cr:mask_surface(is, layout.padding, layout.padding)
  -- 1. Generate inactive icon.
  final_set.inactive = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.inactive)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(is, layout.padding, layout.padding)
  cr:paint()
  -- Selected.
  final_set.selected.inactive = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.inactive)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(is, layout.padding, layout.padding)
  cr:paint()
  -- Mouse hover.
  final_set.hover.inactive = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.hover.inactive)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(is, layout.padding, layout.padding)
  cr:paint()
  -- Selected and hover.
  final_set.selected.hover.inactive = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.hover.inactive)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(is, layout.padding, layout.padding)
  cr:paint()
  -- 2. Generate active icon.
  final_set.active = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.active)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(as, layout.padding, layout.padding)
  cr:paint()
  -- Selected.
  final_set.selected.active = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.active)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(as, layout.padding, layout.padding)
  cr:paint()
  -- Mouse hover.
  final_set.hover.active = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.hover.active)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(as, layout.padding, layout.padding)
  cr:paint()
  -- Selected and hover.
  final_set.selected.hover.active = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.hover.active)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(as, layout.padding, layout.padding)
  cr:paint()
  -- 3. Generate highlight icon.
  final_set.highlight = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.highlight)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(hs, layout.padding, layout.padding)
  cr:paint()
  -- Selected.
  final_set.selected.highlight = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.highlight)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(hs, layout.padding, layout.padding)
  cr:paint()
  -- Mouse hover.
  final_set.hover.highlight = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.hover.highlight)
  cr:set_source_rgb(color2rgb(beautiful.bg_normal))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(hs, layout.padding, layout.padding)
  cr:paint()
  -- Selected and hover.
  final_set.selected.hover.highlight = cairo.ImageSurface.create(cairo.Format.RGB32, icon_size, icon_size)
  local cr = cairo.Context.create(final_set.selected.hover.highlight)
  cr:set_source_rgb(color2rgb(beautiful.bg_focus))
  cr:rectangle(0, 0, icon_size, icon_size)
  cr:fill()
  cr:set_source_surface(halo, 0, 0)
  cr:paint()
  cr:set_source_surface(hs, layout.padding, layout.padding)
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
      local inactive_surface = assert(svg_scaled_surface("inactive_"..tag.name ,inactive, revision, layout.icon_size, layout.icon_size))
      local active_surface = assert(svg_scaled_surface("active_"..tag.name ,active, revision, layout.icon_size, layout.icon_size))
      local highlight_surface = assert(svg_scaled_surface("highlight_"..tag.name, highlight, revision, layout.icon_size, layout.icon_size))
      tag.icon_set = generate_icon_set(inactive_surface, active_surface, highlight_surface)
    else
      print("Could not load icon "..tag.icon..". "..msg)
    end
    print("Loaded icons for: "..tag.name)
  end
end

-- Tag Renderer.
-- ct constains wibox, drawable, dpi and screen.
-- cr is the cairo context.
local function render_tag(self, ct, cr, w, h)
  -- print("Rendering")
  -- First prepare the cairo context.
  for i, tag in ipairs(tag_registry) do
    -- Size of main icon plus padding.
    local slot_size = layout.padding*2 + layout.icon_size
    -- Calculate destination offset (top left corner).
    local offset = (i-1)*(slot_size + layout.spacing)
    local iconset = tag.icon_set
    -- Background.
    if tag.instance.selected then
      iconset = iconset.selected
    end
    -- Hover halo.
    if tag == self.hovered_tag then
      iconset = iconset.hover
    end
    -- State.
    local icon = iconset.inactive
    local clients = tag.instance:clients()
    local client_count = #clients
    if client_count > 0 then
      icon = iconset.active
      for i, c in ipairs(clients) do
        if client.urgent then
          icon = iconset.highlight
        end
      end
    end
    -- Render.
    cr:set_source_surface(icon, offset, 0)
    cr:paint()
    -- Client count/lock bubble.
  end
end

-- Client grabbing state.
local waiting_for_id = nil
local waiting_tag_index = nil
local waiting_timestamp = os.time()

-- Handlers for finishing up spawn events.
local function handle_client_ready(args)
  print(string.format("While waiting for '%s', client '%s' got ready.", waiting_for_id, args.id))
  if args.id == waiting_for_id then
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
          waiting_timestamp = os.time()
          print(string.format("Tag %s waiting for %s (pid: %i) on id %s [%i/%i]", selected.name, selected.spawn_cmd[next_index], pid, id, next_index, #selected.spawn_cmd))
        else
          -- Spawn errored. Error message is stored in pid.
          print(string.format("Could not spawn '%s'(pid:%d)", selected.spawn_cmd, pid))
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
    print("For some reason spawn '"..args.id.."' failed to start.")
  end
end

-- Autostart handler.
local function autostart()
  for _, tag in ipairs(tag_registry) do
    if tag.auto_spawn then
      if #tag.instance:clients() == 0 then
        if type(tag.spawn_cmd)=="table" then
          local reaction_name = tag.name
          local reaction_table = tag.spawn_cmd
          local reaction_index = 0
          local function reaction()
            -- Continue reaction.
            reaction_index = reaction_index + 1
            if reaction_table[reaction_index] then
              print("Autostart", reaction_name..":", reaction_table[reaction_index])
              spawn(reaction_table[reaction_index], false, reaction)
            end
          end
          -- Start 'reaction'
          reaction()
        elseif type(tag.spawn_cmd)=="string" and #tag.spawn_cmd~=0 then
          print("Autostart "..tag.name..": "..tag.spawn_cmd)
          spawn(tag.spawn_cmd, false)
        end
      else
        print("Can not autostart "..tag.name.." because it is non empty!")
      end
    end
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
  -- Register auto start handler.
  table.insert(AFTER_INIT, autostart)
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
    local h = layout.icon_size + layout.padding*2
    local w = h*l + layout.spacing * (l-1)
    return w, h
  end
  function wtl:_redraw(w)
    self:emit_signal("widget::redraw_needed")
  end
  function wtl:_on_mouse_move(x, y)
    if y >= layout.padding and y <= (layout.padding + layout.icon_size) then
      for i, tag in ipairs(tag_registry) do
        -- Size of main icon plus padding.
        local slot_size = layout.padding*2 + layout.icon_size
        -- Calculate x offset of current icon.
        local offset = (i-1)*(slot_size + layout.spacing) + layout.padding
        local end_offset = (i)*slot_size + (i-1)*layout.spacing
        if x >= offset and x <= end_offset then
          -- Hit
          if self.hovered_tag ~= tag then
            self.hovered_tag = tag
            if tag.locked then
              scr.bar.cursor = layout.locked_cursor
            elseif tag.instance.selected then
              scr.bar.cursor = layout.invalid_cursor
            else
              scr.bar.cursor = layout.hover_cursor
            end
            self:_redraw()
          end
          return
        end
      end
    end
    -- No hit, reset widget.
    if self.hovered_tag then
      self.hovered_tag = nil
      scr.bar.cursor = layout.default_cursor
      self:_redraw()
    end
  end
  -- Events.
  local function redraw()
    wtl:_redraw()
  end
  wtl:connect_signal("mouse::leave", function()
    -- Reset hover status when mouse leaves.
    wtl.hovered_tag = nil
    scr.bar.cursor = layout.default_cursor
    wtl:_redraw()
  end)
  -- Mouse events
  wtl:connect_signal("button::release", function(w, lx, ly, button, mods, r)
    if #mods == 0 and w.hovered_tag then
      tag = w.hovered_tag
      -- Left mouse click selects.
      if button == 1 then
        api.select_tag(tag.index)
      end
      -- Right mouse click locks.
      if button == 3 then
        tag.locked = not tag.locked
      end
    end
  end)
  -- Redraw when tags change state.
  for _, tag in ipairs(tag_registry) do
    tag.instance:connect_signal("tagged", redraw)
    tag.instance:connect_signal("untagged", redraw)
    tag.instance:connect_signal("property::urgent_count", redraw)
  end
  scr:connect_signal("tag::history::update", redraw)
  return wtl
end

-- Returns true if the request was valid and accepted.
function api.select_tag(tag_id)
  local selected = tag_registry[tag_id]
  local tag = selected.instance
  -- Test lock.
  if selected.locked then
    print("Tag is locked...")
    return false
  end
  -- Test if tag has any clients.
  if #tag:clients() ~= 0 then
    -- If it has then switch to it.
    selected.waiting = false
    tag:view_only()
    return true
  elseif selected.waiting and os.difftime(os.time(), waiting_timestamp) <= tags_spawn_timeout_sec then
    print("Please be patient...")
    return false
  elseif selected.spawn_cmd and #selected.spawn_cmd~=0 then
    -- Else start the default program(if any) and switch to it when window is ready.
    if type(selected.spawn_cmd)=="table" then
      local pid, id = spawn(selected.spawn_cmd[1], true)
      if type(pid)=="number" then
        waiting_for_id = id
        waiting_tag_index = selected.index
        selected.waiting = 1
        waiting_timestamp = os.time()
        print(string.format("Tag %s waiting for %s (pid: %i) on id %s [%i/%i]", selected.name, selected.spawn_cmd[1], pid, id, 1, #selected.spawn_cmd))
        return true
      else
        -- Spawn errored. Error message is stored in pid.
        print("Could not spawn \""..selected.spawn_cmd.."\": "..pid)
        return false
      end
    else
      local pid, id = spawn(selected.spawn_cmd, true)
      if type(pid)=="number" then
        waiting_for_id = id
        waiting_tag_index = selected.index
        selected.waiting = true
        waiting_timestamp = os.time()
        print(string.format("Tag %s waiting for %s (pid: %i) on id %s", selected.name, selected.spawn_cmd, pid, id))
        return true
      else
        -- Spawn errored. Error message is stored in pid.
        print("Could not spawn \""..selected.spawn_cmd.."\": "..pid)
        return false
      end
    end
  else
    -- There is nothing else to do, so just log this.
    print(string.format("Tried starting tag `%s` but no command is configured!", selected.name))
    return false
  end
end

function api.register_buttons(keyboard, mousekey)
  -- Register keyboard shortcuts.
  for _, obj in ipairs(tag_registry) do
    local new_key = awful.key({modkey}, obj.key, function()
      api.select_tag(obj.index)
    end)
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