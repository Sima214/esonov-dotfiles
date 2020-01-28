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
-- Bash completion
local comp = awful.completion
comp.bashcomp_load("/usr/share/bash-completion/bash_completion")
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

-- TODO: end

-- Command prompt control.
local function enable_cmd_box(scr)
  -- Correct location and make cmd_box appear.
  awful.placement.under_mouse(scr.cmd_box)
  scr.cmd_box.visible = true
end
local function disable_cmd_box(scr)
  -- Make cmd_box disappear.
  scr.cmd_box.visible = false
end
local function simple_prompt(scr)
  -- Single prompt for launching programs.
  awful.prompt.run({
                    prompt="$ ", textbox=scr.cmd_prompt.widget,
                    done_callback=function() disable_cmd_box(scr) end,
                    exe_callback=awful.spawn,
                    completion_callback = comp.shell,
                    history_path = conf_path.."/shell.hist"
                  })
end
local function lua_prompt(scr)
  -- Access internals of the WM.
  awful.prompt.run({
                    prompt="> ", textbox=scr.cmd_prompt.widget,
                    done_callback=function() disable_cmd_box(scr) end,
                    exe_callback = awful.util.eval,
                    history_path = conf_path.."/lua.hist"
                  })
end

local terminal_box = awful.key({modkey}, "r", function() local scr=awful.screen.focused();enable_cmd_box(scr);simple_prompt(scr) end)
local lua_box = awful.key({modkey}, "l", function() local scr=awful.screen.focused();enable_cmd_box(scr);lua_prompt(scr) end)
globalkeys = gears.table.join(globalkeys, terminal_box, lua_box)

-- Application shortcuts.
local screenshot = awful.key({}, "Print", function() awful.spawn("gscreenshot") end)
local screenshot_direct = awful.key({modkey}, "Print", function() awful.spawn.with_shell("gscreenshot-cli -f "..screenshot_output) end)
local screenshot_select = awful.key({modkey}, "Insert", function() awful.spawn.with_shell("gscreenshot-cli -s -f "..screenshot_output) end)
globalkeys = gears.table.join(globalkeys, screenshot, screenshot_direct, screenshot_select)

-- Tag keyboard control.
globalkeys = tags.register_buttons(globalkeys, nil)

-- Register keybinds.
root.keys(globalkeys)