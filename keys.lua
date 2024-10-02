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
local launcher = require("launcher")
local clients = require("clients")

-- Generic key bindings.
local function awesome_permanent_quit()
  touch("~/no_gui")
  awesome.quit()
end

globalkeys = gears.table.join(
    awful.key({modkey}, "s", hotkeys_popup.show_help, {description="Show help.", group="awesome"}),
    awful.key({modkey, "Control"}, "Escape", awesome_permanent_quit, {description = "Exit awesome.", group = "awesome"}),
    awful.key({modkey, "Control"}, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({modkey, "Control"}, "q", awesome.quit, {description = "quit awesome", group = "awesome"}),
    -- Standard programs
    awful.key({modkey}, "Return", function() awful.spawn(terminal) end, {description = "Open a terminal.", group = "Command prompt"})
)

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

local function trigger_simple_prompt()
  local scr = awful.screen.focused()
  enable_cmd_box(scr)
  simple_prompt(scr)
end

local function trigger_lua_prompt()
  local scr = awful.screen.focused()
  enable_cmd_box(scr)
  lua_prompt(scr)
end

local terminal_box = awful.key({modkey}, "r", trigger_simple_prompt, {description = "Open a shell prompt.", group = "Command prompt"})
local lua_box = awful.key({modkey}, "l", trigger_lua_prompt, {description = "Open a lua prompt.", group = "Command prompt"})
globalkeys = gears.table.join(globalkeys, terminal_box, lua_box)

-- Application shortcuts.
local screenshot = awful.key({}, "Print", function() awful.spawn("gscreenshot") end)
local screenshot_direct = awful.key({modkey}, "Print", function() awful.spawn.with_shell("gscreenshot-cli -f "..screenshot_output) end)
local screenshot_select = awful.key({modkey}, "Insert", function() awful.spawn.with_shell("gscreenshot-cli -s -f "..screenshot_output) end)
globalkeys = gears.table.join(globalkeys, screenshot, screenshot_direct, screenshot_select)

-- Tag keyboard control.
globalkeys = tags.register_buttons(globalkeys)
globalkeys = launcher.register_buttons(globalkeys)
globalkeys = clients.register_buttons(globalkeys)

-- Misc
local misc_01 = awful.key({modkey, "Shift"}, "m", function()
  awful.spawn("switcher -mon hdmi2")
end, {description = "Switch display to X11", group = "Misc"})
local misc_02 = awful.key({modkey, "Shift"}, "l", function()
  awful.spawn("switcher -mon dp -delay 1500 -mon hdmi2")
end, {description = "Clear monitor lockup and switch display to X11", group = "Misc"})
local misc_03 = awful.key({modkey, "Shift"}, "n", function()
  awful.spawn("switcher -mon dp -delay 500 -vt 2")
end, {description = "Switch display connection to Weston", group = "Misc"})
globalkeys = gears.table.join(globalkeys, misc_01, misc_02, misc_03)

-- Register keybinds.
root.keys(globalkeys)