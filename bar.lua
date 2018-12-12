-- Load basic awesome libs.
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
-- Widgets
local wibox = require("wibox")
local widget_utils = require("wibox.widget.base")
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

-- Track prompt size changes.
local function track_prompt(scr)
  -- Correct size after each layout update.
  local w, h = scr.cmd_prompt.widget:get_preferred_size(scr)
  scr.cmd_box.width = w + 2
  scr.cmd_box.height = h + 2
  -- Make sure we do not head off-screen.
  awful.placement.no_offscreen(scr.cmd_box)
end

local function on_new_screen(scr)
  print("New screen:", scr.index)
  -- Create a floating promptbox for each screen.
  local cmd_box = wibox({ontop=true, visible=false, opacity=0.82, type="normal",
                         x=0, y=0, width=4, height=4, screen=scr})
  local cmd_prompt = awful.widget.prompt()
  cmd_prompt.widget:connect_signal("widget::layout_changed", function(w) track_prompt(scr) end)
  cmd_box:setup({
    cmd_prompt,
    left   = 1,
    right  = 1,
    top    = 1,
    bottom = 1,
    layout=wibox.container.margin
  })
  scr.cmd_prompt = cmd_prompt
  scr.cmd_box = cmd_box
  -- Register all the tags.
  tags.init(scr)
  -- Generate the taglist widget.
  local taglist = tags.gen_widget(scr)
  local taglist_height = select(2, taglist:fit({}, 128, 128))
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