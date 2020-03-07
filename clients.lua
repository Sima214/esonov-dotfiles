local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")
-- Coop
local tags = nil

-- TODO: esonovify

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
      c:raise()
      c.fullscreen = not c.fullscreen
    end,
    {description = "Toggle fullscreen.", group = "Clients"}
  ),
  awful.key({modkey, "Shift"}, "c", function(c) c:kill() end,
            {description = "close", group = "client"}),
  awful.key({modkey, "Control"}, "space", awful.client.floating.toggle,
            {description = "toggle floating", group = "client"}),
  awful.key({modkey}, "m",
    function(c)
      c.maximized = not c.maximized
      c:raise()
    end ,
    {description = "(un)maximize", group = "client"})
)

-- Event handlers
client.connect_signal("manage", function(c)
  -- Debug
  print("New client: ", client2string(c))
  if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
    -- Prevent clients from being unreachable after screen count changes.
    awful.placement.no_offscreen(c)
  end
  -- TODO: resize to fit screen. Handle dialogs.
end)

client.connect_signal("mouse::enter", function(c)
  -- Selective sloppy focus
  if awful.client.focus.filter(c) then
    client.focus = c
  end
end)

client.connect_signal("request::titlebars", function(c)
  print("Titlebars for "..client2string(c))
  -- Fine! Here you go.
  awful.titlebar(c):setup {
    { -- Icon
      awful.titlebar.widget.iconwidget(c),
      layout  = wibox.layout.fixed.horizontal
    },
    { -- Title
      align  = "center",
      widget = awful.titlebar.widget.titlewidget(c)
    },
    layout = wibox.layout.align.horizontal
  }
end)

-- Private functions.
local function update_borderless(tag_obj)
  local bar = tag_obj.instance.screen.bar
  -- Tag must be selected.
  if bar.visible == tag_obj.borderless then
    bar.visible = not tag_obj.borderless
  end
end

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
  -- Borderless handler.
  scr:connect_signal("tag::history::update", function() update_borderless(tags.registry[scr.selected_tag.name]) end)
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
  local borderless_key = awful.key({modkey}, "b",
        function()
          local tag_obj = tags.registry[awful.screen.focused().selected_tag.name]
          tag_obj.borderless = not tag_obj.borderless
          update_borderless(tag_obj)
        end,
        {description = "Toogle visibility of the WM Bar.", group = "Clients"})
  keyboard = gears.table.join(keyboard, switch_key, borderless_key)
  return keyboard, mousekey
end

return api