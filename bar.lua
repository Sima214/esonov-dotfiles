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
    layout=wibox.container.margin
  })
  scr.cmd_prompt = cmd_prompt
  scr.cmd_box = cmd_box
  -- Register all the tags.
  tags.init(scr)
  -- Generate the taglist widget.
  scr.taglist = tags.gen_widget(scr)
  local taglist_height = select(2, scr.taglist:fit({}, screen_width, screen_height))
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
          awful.spawn.easy_async_with_shell(string.format("kill -9 %d", c.pid), function(_, _, _, exitcode)
            if exitcode ~= 0 then
              naughty.notify({text=string.format("Couldn't kill client with pid %d", c.pid)})
            end
          end)
        end
      end)
    end
  }
  scr.tasklist = awful.widget.tasklist {
    screen = scr,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = awful.button({}, 1, on_click_task),
    widget_template = tasklist_template
  }
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
            markup = "",
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