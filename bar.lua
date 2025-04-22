-- Load basic awesome libs.
local awful = require("awful")
local gears = require("gears")
local menubar = require("menubar")
local naughty = require("naughty")
-- Widgets
local wibox = require("wibox")
local widget_utils = require("wibox.widget.base")
local common = awful.widget.common
-- Theming utilities.
local layout = require("beautiful").get().bar_layout
-- Helpers.
local tags = require("tags")
local clients = require("clients")
local launcher = require("launcher")
local weather = require("weather")

-- Event handlers.
-- Track prompt size changes.
local function track_prompt(scr)
  -- Correct size after each layout update.
  local w, h = scr.cmd_prompt.widget:get_preferred_size(scr)
  scr.cmd_box.width = w + 2
  scr.cmd_box.height = h + 2
  -- Make sure we do not head off-screen.
  awful.placement.no_offscreen(scr.cmd_box)
end

local global_screen = nil
local function on_new_screen(scr)
  -- New screen.
  print(string.format("New screen: index=%d, width=%d, height=%d", scr.index, scr.geometry.width, scr.geometry.height))
  if global_screen then
    debug_error("Only one screen supported per wm instance!")
    return
  end
  global_screen = scr
  local screen_width, screen_height = scr.geometry.width, scr.geometry.height
  -- Create a floating promptbox for each screen.
  local cmd_box = wibox({ontop=true, visible=false, opacity=0.82, type="dialog",
                         x=0, y=0, width=4, height=4, screen=scr})
  local cmd_prompt = awful.widget.prompt()
  cmd_prompt.widget:connect_signal("widget::layout_changed", function(w) track_prompt(scr) end)
  cmd_box:setup({
    cmd_prompt,
    left   = 1,
    right  = 1,
    top    = 1,
    bottom = 1,
    layout = wibox.container.margin
  })
  scr.cmd_prompt = cmd_prompt
  scr.cmd_box = cmd_box
  -- Register all the tags.
  tags.init(scr)
  -- Generate the taglist widget.
  scr.taglist = tags.gen_widget(scr)
  launcher.register_taglist(scr.taglist)
  local taglist_height = select(2, scr.taglist:fit({}, screen_width, screen_height))
  -- Generate the tasklist widget.
  scr.tasklist = clients.gen_widget(scr)
  -- Generate the weather widget.
  scr.weather = weather.gen_widget(scr, taglist_height)
  -- Limit bar height.
  local wibar_height = taglist_height + layout.tasklist_height
  -- Create the wibar to hold the 'always visible' widgets.
  scr.bar = awful.wibar({
    position = "top",
    height = wibar_height,
    screen = scr
  })
  scr.bar:setup {
    layout = wibox.layout.grid,
    forced_num_cols = 1,
    forced_num_rows = 2,
    homogeneous = false,
    vertical_expand = false,
    horizontal_expand = true,
    -- Up
    {
      forced_width = scr.geometry.width,
      widget = wibox.container.background,
      {
        layout = wibox.layout.align.horizontal,
        {
          layout = wibox.layout.fixed.horizontal,
          {
            -- TODO: add system monitors
            id = "placeholder",
            markup = "                        ",
            widget = wibox.widget.textbox
          }
        },
        {
          scr.taglist,
          widget = wibox.container.place
        },
        {
          awful.widget.keyboardlayout(),
          {
            -- Constraint systray, as some apps extend over to the tasklist area.
            layout = wibox.container.constraint,
            height = taglist_height,
            strategy = "max",
            wibox.widget.systray()
          },
          -- Place weather widget.
          scr.weather,
          wibox.widget.textclock(),
          -- Global/Current client title bar buttons.
          {
            id = "global_close",
            image = layout.close_image,
            resize_allowed = true,
            forced_height = taglist_height,
            buttons = awful.button({}, 1, nil, function(...)
              f = client.focus
              if f then
                f:kill()
              end
            end),
            widget = wibox.widget.imagebox
          },
          layout = wibox.layout.fixed.horizontal
        }
      },
    },
    -- Down
    scr.tasklist
  }
  -- Extra events.
  local global_close = scr.bar:get_children_by_id("global_close")[1]
  global_close:connect_signal("mouse::enter", function(w) w.image = layout.close_hover_image end)
  global_close:connect_signal("mouse::leave", function(w) w.image = layout.close_image end)
  local last_x, last_y = -1, -1
  -- Awesome does not distribute mouse::move events to widgets automatically, so we do this ourselves.
  scr.bar:connect_signal("mouse::move", function(wibox, x, y)
    -- By default we receive mouse events as fast as possible, so we rate limit them here.
    if last_x == x and last_y == y then
      return
    else
      last_x = x
      last_y = y
    end
    local widgets = wibox:find_widgets(x, y)
    for _, wt in ipairs(widgets) do
      local w = wt.widget
      if w and w._on_mouse_move then
        -- Stop on the first one which returns true.
        if w:_on_mouse_move(x - wt.x, y - wt.y) then
          return
        end
      end
    end
  end)
  -- Report final wibar layout.
  print(string.format("Wibar: w:%d, h:%d", scr.bar.width, scr.bar.height))
end

-- Event registration.
awful.screen.connect_for_each_screen(on_new_screen)