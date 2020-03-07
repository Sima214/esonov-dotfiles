local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local screen = awful.screen
-- Native libs.
local lgi = require("lgi")
local cairo = lgi.cairo
local pango = lgi.Pango
local pangocairo = lgi.PangoCairo
-- Helpers.
local clients = require("clients")
-- Extra libs.
local lfs = require("lfs")

-- Settings.
local layout = beautiful.get().tag.layout
local colors_inactive = beautiful.get().tag.colors.inactive
local colors_active = beautiful.get().tag.colors.active
local colors_highlight = beautiful.get().tag.colors.highlight
local colors_halo = beautiful.get().tag.colors.halo
local colors_bubble = beautiful.get().tag.colors.bubble

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

-- Export internal state.
api.registry = tag_registry

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

local function generate_halo(icon_size, shape, color)
  local ret = cairo.ImageSurface.create(cairo.Format.ARGB32, icon_size, icon_size)
  local cr = cairo.Context.create(ret)
  cr:set_source_rgba(color2rgba(color))
  cr:scale(layout.halo_scale, layout.halo_scale)
  cr:mask_surface(shape, layout.padding, layout.padding)
  return ret
end

-- Creates a cairo surface and context of the given size and clears with default background color.
local function generate_icon_cairo_base(color, w, h)
  h = h or w
  local surface = cairo.ImageSurface.create(cairo.Format.RGB32, w, h)
  local cr = cairo.Context.create(surface)
  cr:set_source_rgb(color2rgb(color))
  cr:rectangle(0, 0, w, h)
  cr:fill()
  return surface, cr
end

-- Apply a surface on a cairo context.
local function draw_surface(cr, surface, offset_x, offset_y)
  cr:set_source_surface(surface, offset_x, offset_y or offset_x)
  cr:paint()
end

local function generate_icon_set(output_set, name, icon_size, input_surface, halo)
  -- Normal.
  local normal, cr = generate_icon_cairo_base(beautiful.bg_normal, icon_size)
  draw_surface(cr, input_surface, layout.padding)
  -- Selected.
  local selected, cr = generate_icon_cairo_base(beautiful.bg_focus, icon_size)
  draw_surface(cr, input_surface, layout.padding)
  -- Mouse hover.
  local hover, cr = generate_icon_cairo_base(beautiful.bg_normal, icon_size)
  draw_surface(cr, halo, 0)
  draw_surface(cr, input_surface, layout.padding)
  -- Selected and hover.
  local selected_hover, cr = generate_icon_cairo_base(beautiful.bg_focus, icon_size)
  draw_surface(cr, halo, 0)
  draw_surface(cr, input_surface, layout.padding)
  -- Store results.
  output_set[name] = normal
  output_set.selected[name] = selected
  output_set.hover[name] = hover
  output_set.selected.hover[name] = selected_hover
end

local function generate_icons(inactive_surface, active_surface, highlight_surface)
  local icon_size = layout.icon_size + layout.padding * 2
  local final_set = {selected = {hover = {}}, hover = {}}
  -- 0. Generate outline/halos.
  local halo_inactive = generate_halo(icon_size, inactive_surface, colors_halo.inactive)
  local halo_active = generate_halo(icon_size, inactive_surface, colors_halo.active)
  -- 1. Generate inactive icon.
  generate_icon_set(final_set, "inactive", icon_size, inactive_surface, halo_inactive)
  -- 2. Generate active icon.
  generate_icon_set(final_set, "active", icon_size, active_surface, halo_active)
  -- 3. Generate highlight icon.
  generate_icon_set(final_set, "highlight", icon_size, highlight_surface, halo_active)
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
      local inactive_surface = assert(svg_scaled_surface("inactive_"..tag.name, inactive, revision, layout.icon_size, layout.icon_size))
      local active_surface = assert(svg_scaled_surface("active_"..tag.name, active, revision, layout.icon_size, layout.icon_size))
      local highlight_surface = assert(svg_scaled_surface("highlight_"..tag.name, highlight, revision, layout.icon_size, layout.icon_size))
      tag.icon_set = generate_icons(inactive_surface, active_surface, highlight_surface)
    else
      print(string.format("Could not load icons for `%s` (%s)!", tag.icon, msg))
    end
    print(string.format("Loaded icons for `%s`.", tag.name))
  end
end

--- Ported from textbox
local function setup_text_layout(box, width, height, dpi)
  box.bubble_text_layout.width = pango.units_from_double(width)
  box.bubble_text_layout.height = pango.units_from_double(height)
  assert(dpi, "No DPI provided")
  if box._dpi ~= dpi then
      box._dpi = dpi
      box.bubble_text_context:set_resolution(dpi)
      box.bubble_text_layout:context_changed()
  end
end

-- Tag Renderer.
-- ct constains wibox, drawable, dpi and screen.
-- cr is the cairo context.
local function render_tag(self, ct, cr, w, h)
  setup_text_layout(self, w, h, ct.dpi)
  for i, tag in ipairs(tag_registry) do
    -- Size of main icon plus padding.
    local slot_size = layout.padding * 2 + layout.icon_size
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
        if c.urgent then
          icon = iconset.highlight
        end
      end
    end
    -- Render.
    cr:set_source_surface(icon, offset, 0)
    cr:paint()
    -- Client bubble.
    if tag.locked then
      cr:set_source_rgba(color2rgba(colors_bubble.locked))
    elseif tag.instance.selected then
      cr:set_source_rgba(color2rgba(colors_bubble.selected))
    elseif client_count ~= 0 then
      cr:set_source_rgba(color2rgba(colors_bubble.active))
    elseif tag.spawning_index then
      cr:set_source_rgba(color2rgba(colors_bubble.waiting))
    else
      cr:set_source_rgba(color2rgba(colors_bubble.inactive))
    end
    cr:arc(offset + layout.bubble_offset_x, layout.bubble_offset_y, layout.bubble_radius, 0.0, math.pi*2.0)
    cr:fill()
    -- Client count.
    if client_count ~= 0 or tag.spawning_index then
      self.bubble_text_layout:set_text(tag.spawning_index and '!' or tostring(client_count))
      cr:update_layout(self.bubble_text_layout)
      local _, logical = self.bubble_text_layout:get_pixel_extents()
      if tag.instance.selected then
        cr:set_source_rgba(color2rgba(colors_bubble.font.selected))
      else
        cr:set_source_rgba(color2rgba(colors_bubble.font.active))
      end
      cr:move_to(offset + layout.bubble_text_offset_x, layout.bubble_text_offset_y)
      cr:show_layout(self.bubble_text_layout)
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
  clients.setup(scr, tag_registry)
end

function api.gen_widget(scr)
  -- Preload resources required for rendering the widget.
  preload_resources()
  -- Define the widget.
  local wtl = wibox.widget.base.make_widget()
  wtl.draw = render_tag
  -- Prepare bubble text rendering.
  wtl.bubble_text_context = pangocairo.font_map_get_default():create_context()
  wtl.bubble_text_layout = pango.Layout.new(wtl.bubble_text_context)
  wtl.bubble_text_layout:set_font_description(beautiful.get_font(layout.bubble_font))
  -- Tooltip
  wtl._tooltip = awful.tooltip {text = "", visible = false}
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
  function wtl:mouse_effects_clear()
    -- Reset mouse move triggered stuff when mouse leaves.
    self._tooltip.visible = false
    self.hovered_tag = nil
    scr.bar.cursor = layout.default_cursor
    self:_redraw()
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
            -- Update tooltip.
            self._tooltip.visible = true
            self._tooltip.text = tag.tooltip
            -- Update cursor.
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
      self:mouse_effects_clear()
    end
  end
  -- Events.
  local function redraw()
    wtl:_redraw()
  end
  wtl:connect_signal("mouse::leave", function() wtl:mouse_effects_clear() end)
  -- Mouse events
  wtl:connect_signal("button::press", function(w, lx, ly, button, mods, hits)
    local tag = w.hovered_tag
    if #mods == 0 and tag then
      -- Right mouse click locks.
      if button == 3 and #tag.instance:clients() == 0 then
        print(string.format("Tag's %d lock toogled.", tag.index))
        tag.locked = not tag.locked
        scr.bar.cursor = tag.locked and layout.locked_cursor or (tag.instance.selected and layout.invalid_cursor or layout.hover_cursor)
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

function api.register_buttons(keyboard)
  -- Register keyboard shortcuts.
  -- Return new bindings.
  return keyboard
end

return api