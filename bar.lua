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
  print("Registering new screen:", scr.index)
  -- Register all the tags(workspaces).
  tags.init(scr)
  -- Generate the taglist widget.
  local taglist = tags.gen_widget(scr)
  -- TODO: esonovify
  -- Create a promptbox for each screen
  scr.mypromptbox = awful.widget.prompt()
  -- Create a tasklist widget.
  scr.mytasklist = awful.widget.tasklist(scr, awful.widget.tasklist.filter.currenttags, awful.button({ }, 1, on_click_task))
  -- Create the wibox 
  scr.mywibox = awful.wibar({ position = "top", screen = scr })
  -- Add widgets to the wibox 
  scr.mywibox:setup {
    layout = wibox.layout.align.horizontal,
    {-- Left widgets
      layout = wibox.layout.fixed.horizontal,
      taglist,
      scr.mypromptbox
    },-- Middle widget
    scr.mytasklist,
    {-- Right widgets
      layout = wibox.layout.fixed.horizontal,
      awful.widget.keyboardlayout(),
      wibox.widget.systray(),
      wibox.widget.textclock(),
      scr.mylayoutbox
    }
  }
  print("Registered new screen:", scr.index)
end

-- Event registration.
awful.screen.connect_for_each_screen(on_new_screen)