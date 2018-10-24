local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")

-- TODO: esonovify
local clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

local clientkeys = gears.table.join(
  awful.key({ modkey,           }, "f",
      function (c)
          c.fullscreen = not c.fullscreen
          c:raise()
      end,
      {description = "toggle fullscreen", group = "client"}),
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
    -- All clients will match this rule.
    {
      rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen}
    },
    {
      rule_any = {type = { "normal", "dialog" }},
      properties = { titlebars_enabled = true }
    }
  }
  print("Restraining clients...")
  for _, tag in ipairs(tags) do
    local new_rule = {rule_any = tag.grab_filters, except_any = nograb_filters, properties = { tag = tag.name }}
    table.insert(awful.rules.rules, new_rule)
  end
end

return api