-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Local libraries.
local tags = require("tags")

-- TODO: esonovify
-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="Show help.", group="awesome"}),
    awful.key({ modkey, "Control" }, "Escape", function() touch("~/no_gui"); awesome.quit() end,
              {description = "Exit awesome.", group = "awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "Switch to the previous tag.", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "Switch to the next tag.", group = "tag"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            client.focus = awful.client.next(1)
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "Switch between clients.", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Control"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)
-- TODO: end

-- Command prompt control.
local function enable_cmd_box(scr)
  print("Showing prompt!")
  -- Correct location and make cmd_box appear.
  awful.placement.next_to_mouse(scr.cmd_box)
  scr.cmd_box.visible = true
end
local function disable_cmd_box(scr)
  print("Hiding prompt!")
  -- Make cmd_box disappear (also correct focused client).
  -- TODO: restore focus?
  scr.cmd_box.visible = false
end
local function simple_prompt(scr)
  -- Single prompt for launching programs.
  -- TODO: tracking!
  print("Launching simple prompt!")
  awful.prompt.run({prompt="Shell: ", textbox=scr.cmd_prompt.widget, done_callback=function() disable_cmd_box(scr) end, exe_callback=awful.spawn})
end
local terminal_box = awful.key({modkey}, "r", function() local scr=awful.screen.focused();enable_cmd_box(scr);simple_prompt(scr) end)
local lua_box = awful.key({ modkey }, "x",
          function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
          }
end)
    globalkeys = gears.table.join(globalkeys, terminal_box, lua_box)

-- Tag keyboard control.
globalkeys = tags.register_buttons(globalkeys, nil)

-- Register keybinds.
root.keys(globalkeys)