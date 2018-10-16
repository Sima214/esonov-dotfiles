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
  -- Register all the tags.
  tags.init(scr)
  -- Generate the taglist widget.
  local taglist = tags.gen_widget(scr)
  -- TODO: esonovify
  -- Create a promptbox for each screen
  scr.mypromptbox = awful.widget.prompt()
  -- Create a tasklist widget.
  scr.mytasklist = awful.widget.tasklist(scr, awful.widget.tasklist.filter.currenttags, awful.button({ }, 1, on_click_task))
  -- Create the wibox 
  scr.mywibox = awful.wibar({ position = "top", height = 36, screen = scr })
  -- Add widgets to the wibox 
  scr.mywibox:setup {
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
      scr.mypromptbox,
      awful.widget.keyboardlayout(),
      {
        layout = wibox.container.constraint,
        height = 26,
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