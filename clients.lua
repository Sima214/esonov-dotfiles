local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")
-- Widgets
local wibox = require("wibox")
-- Theming utilities.
local layout = require("beautiful").get().bar_layout
-- Coop
local tags = nil

-- Extra client methods.
local function force_kill(c)
  if not awesome.kill(c.pid, 9) then
    naughty.notify({text=string.format("Couldn't kill client with pid %d", c.pid)})
  end
end

local function toogle_borderless(c)
  c.borderless = not c.borderless
  c:update_borderless()
end

local function update_borderless(c)
  local bar = c.screen.bar
  if bar.visible == c.borderless then
    bar.visible = not c.borderless
  end
end

local clientbuttons = gears.table.join(
  awful.button({}, 1, function(c)
    if client.focus ~= c then
      client.focus = c;
      c:raise()
    end
  end),
  awful.button({modkey}, 1, awful.mouse.client.move),
  awful.button({modkey}, 3, awful.mouse.client.resize)
)

local clientkeys = gears.table.join(
  awful.key({modkey}, "f",
    function(c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    {description = "Toggle fullscreen.", group = "Clients"}
  ),
  awful.key({modkey}, "b", toogle_borderless,
            {description = "Toogle visibility of the WM Bar.", group = "Clients"}),
  awful.key({modkey}, "v",
    function(c)
      c.floating = not c.floating
      c:raise()
    end,
    {description = "Toggle floating property.", group = "Clients"}
  ),
  awful.key({modkey, "Alt"}, "c", function(c) c:kill() end,
            {description = "Close focused client.", group = "Clients"}),
  awful.key({modkey, "Alt"}, "x", force_kill,
            {description = "Force close focused client.", group = "Clients"})
)

-- Event handlers.
client.connect_signal("manage", function(c)
  -- Attach extra properties and methods.
  c.borderless = false
  c.force_kill = force_kill
  c.update_borderless = update_borderless
  c.toogle_borderless = toogle_borderless
  -- Debug
  print("New client: ", client2string(c))
  if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
end)

client.connect_signal("tagged", function(c, t)
  local tag_obj = tags.registry[t.name]
  if tag_obj.locked then
    tag_obj:toogle_lock()
  end
end)

client.connect_signal("focus", update_borderless)

client.connect_signal("mouse::enter", function(c)
  -- Selective sloppy focus
  if awful.client.focus.filter(c) then
    client.focus = c
  end
end)

client.connect_signal("request::titlebars", function(c)
  print("Titlebars for "..client2string(c))
  local theme = beautiful.get()
  -- Fine! Here you go.
  awful.titlebar(c, {
    size = theme.titlebar_height,
    font = theme.titlebar_font
  }):setup {
    { -- Title
      align  = "center",
      widget = awful.titlebar.widget.titlewidget(c)
    },
    layout = wibox.layout.flex.horizontal
  }
  if theme.titlebar_shape then
    c.shape = theme.titlebar_shape
  end
end)

-- Taskbar which behaves more like a tab.
local function on_click_task(c)
  if c ~= client.focus then
    c.minimized = false
    client.focus = c
    c:raise()
  end
end

-- Private functions.

-- API
-- Setup clients filters in respect to tags' settings.
function api.setup(scr, tags_registry)
  -- Delayed load. Avoids infinite loop due to cyclic dependency.
  tags = require("tags")
  -- First set rules.
  awful.rules.rules = {
    {
      -- Default rules
      rule = {},
      properties = {
        border_width = beautiful.border_width,
        border_color = beautiful.border_normal,
        focus = awful.client.focus.filter,
        raise = true,
        keys = clientkeys,
        buttons = clientbuttons,
        titlebars_enabled = false,
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap + awful.placement.no_offscreen
      }
    },
    {
      -- Default tag for normal windows.
      rule = {type = "normal"},
      properties = {tag = tags_registry[#tags_registry].name}
    },
    {
      -- Rule breakers. These are always floating windows.
      rule = {type = "dialog"},
      properties = {
        titlebars_enabled = true
      }
    }
  }
  print("Restraining clients...")
  for _, tag in ipairs(tags_registry) do
    if tag.grab_filters or tag.nograb_filters or tag.grab_filter then
      local new_rule = {
        rule = tag.grab_filter,
        rule_any = tag.grab_filters,
        except_any = tag.nograb_filters,
        properties = {
          tag = tag.name,
          titlebars_enabled = false
        }
      }
      table.insert(awful.rules.rules, #awful.rules.rules, new_rule)
    end
  end
end

function api.gen_widget(scr)
  -- Create the tasklist widget.
  local tasklist_template = {
    {
      {
        {
          id = "tasklist_close",
          widget = wibox.widget.imagebox,
          image = layout.tasklist_close_button_image,
          resize = true,
          forced_height = layout.tasklist_close_button_size,
          forced_width = layout.tasklist_close_button_size
        },
        left   = layout.tasklist_close_margin.left,
        right  = layout.tasklist_close_margin.right,
        top    = layout.tasklist_close_margin.top,
        bottom = layout.tasklist_close_margin.bottom,
        widget = wibox.container.margin
      },
      {
        {
          id     = 'icon_role',
          widget = wibox.widget.imagebox,
        },
        id     = "icon_margin_role",
        left   = layout.tasklist_icon_margin.left,
        right  = layout.tasklist_icon_margin.right,
        top    = layout.tasklist_icon_margin.top,
        bottom = layout.tasklist_icon_margin.bottom,
        widget = wibox.container.margin
      },
      {
        {
          id     = "text_role",
          widget = wibox.widget.textbox,
        },
        id     = "text_margin_role",
        left   = layout.tasklist_title_margin.left,
        right  = layout.tasklist_title_margin.right,
        top    = layout.tasklist_title_margin.top,
        bottom = layout.tasklist_title_margin.bottom,
        widget = wibox.container.margin
      },
      fill_space = true,
      layout     = wibox.layout.fixed.horizontal
    },
    id     = "background_role",
    widget = wibox.container.background,
    create_callback = function(w, c)
      local close_button = w:get_children_by_id("tasklist_close")[1]
      close_button:connect_signal("mouse::enter", function(w) w.image = layout.tasklist_close_button_hover_image end)
      close_button:connect_signal("mouse::leave", function(w) w.image = layout.tasklist_close_button_image end)
      close_button:connect_signal("button::release", function(w, lx, ly, button, mods, r)
        if button == 1 and #mods == 0 then
          c:kill()
        end
        if #mods == 1 and mods[1] == modkey and button == 3 then
          -- Force kill client.
          c:force_kill()
        end
      end)
    end
  }
  return awful.widget.tasklist {
    screen = scr,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = awful.button({}, 1, on_click_task),
    widget_template = tasklist_template
  }
end

function api.register_buttons(keyboard, mousekey)
  local switch_key = awful.key({modkey}, "Tab",
        function()
          client.focus = awful.client.next(1)
          if client.focus then
            client.focus:raise()
          end
        end,
        {description = "Switch between clients.", group = "Clients"})
  for _, obj in ipairs(tags.registry) do
    local new_key = awful.key({modkey, "Control"}, obj.key, function()
      if client.focus then
        client.focus:move_to_tag(obj.instance)
      end
    end,
    {description=string.format("Move focused client to %s", obj.name), group="Clients"})
    keyboard = gears.table.join(keyboard, new_key)
  end
  keyboard = gears.table.join(keyboard, switch_key)
  return keyboard, mousekey
end

return api