local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local wibox = require("wibox")

-- TODO: esonovify

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
  -- Prevent clients from being unreachable after screen count changes.
  if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
    awful.placement.no_offscreen(c)
  end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- NO titlebars
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
  if awful.client.focus.filter(c) then
    client.focus = c
  end
end)

local clientbuttons = gears.table.join(
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)

local clientkeys = gears.table.join(
  awful.key({modkey}, "f",
    function (c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    {description = "toggle fullscreen", group = "client"}
  ),
  awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
            {description = "close", group = "client"}),
  awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
            {description = "toggle floating", group = "client"}),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
            {description = "move to master", group = "client"}),
  awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
            {description = "move to screen", group = "client"}),
  awful.key({ modkey,           }, "m",
    function (c)
      c.maximized = not c.maximized
      c:raise()
    end ,
    {description = "(un)maximize", group = "client"}),
  awful.key({ modkey, "Control" }, "m",
    function (c)
      c.maximized_vertical = not c.maximized_vertical
      c:raise()
    end ,
    {description = "(un)maximize vertically", group = "client"}),
  awful.key({ modkey, "Shift"   }, "m",
    function (c)
      c.maximized_horizontal = not c.maximized_horizontal
      c:raise()
    end ,
    {description = "(un)maximize horizontally", group = "client"})
)

-- Setup clients in respect to the tag settings.
function api.setup(tags)
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
        screen = awful.screen.preferred,
        placement = awful.placement.no_overlap+awful.placement.no_offscreen
      }
    },
    {
      -- Default tag for normal windows.
      rule = { type="normal" },
      properties = { tag = tags[9].name }
    },
    {
      rule_any = { type = {"dialog"} },
      properties = { titlebars_enabled = true }
    }
  }
  print("Restraining clients...")
  for _, tag in ipairs(tags) do
    if tag.grab_filters or tag.nograb_filters or tag.grab_filter then
      local new_rule = {rule = tag.grab_filter, rule_any = tag.grab_filters, except_any = tag.nograb_filters, properties = { tag = tag.name, titlebars_enabled = tags.gap~=0 }}
      table.insert(awful.rules.rules, new_rule)
    end
  end
end

return api