-- Load basic awesome libs.
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
-- Widgets
local wibox = require("wibox")
local common = awful.widget.common
-- Theming utilities.
local dpi = require("beautiful").xresources.apply_dpi
-- Helpers.
local tags = require("tags")

-- Event handlers.
-- Taskbar which behaves more like a tab.
local function on_click_task(c)
  if c ~= client.focus then
    c.minimized = false
    client.focus = c
    c:raise()
    print("Selected "..client2string(c))
  end
end

local function on_new_screen(scr)
  print("New screen:", scr.index)
  -- Create a floating promptbox for each screen.
  local cmd_prompt = awful.widget.prompt()
  local cmd_box = wibox({ontop=true, visible=false, opacity=0.7, widget=cmd_prompt,
                         x=0, y=0, width=4, height=4, screen=scr, type="normal"})
  scr.cmd_prompt = cmd_prompt
  scr.cmd_box = cmd_box
  -- Register all the tags.
  tags.init(scr)
  -- Generate the taglist widget.
  local taglist = tags.gen_widget(scr)
  local taglist_height = select(2, taglist:fit(nil, 128, 128))
  -- TODO: esonovify
  -- Create a tasklist widget.
  scr.mytasklist = awful.widget.tasklist(scr, awful.widget.tasklist.filter.currenttags, awful.button({ }, 1, on_click_task))
  -- Force the tasklist into a fixed size.
  local wibar_height = taglist_height + tasklist_height
  -- Create the wibar to holds the 'always visible' widgets.
  local bar = awful.wibar({ position = "top", height = wibar_height, screen = scr })
  bar:setup {
    layout = wibox.layout.grid,
    forced_num_cols = 1,
    forced_num_rows = 2,
    homogeneous = false,
    vertical_expand = false,
    horizontal_expand = true,
    -- Up
    {
      layout = wibox.layout.fixed.horizontal,
      taglist,
      awful.widget.keyboardlayout(),
      {
        -- Constraint systray, as some apps extend over to the tasklist.
        layout = wibox.container.constraint,
        height = taglist_height,
        strategy = "max",
        wibox.widget.systray()
      },
      wibox.widget.textclock()
    },
    -- Down
    scr.mytasklist
  }
end

-- Event registration.
awful.screen.connect_for_each_screen(on_new_screen)