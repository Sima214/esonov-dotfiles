-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Bash completion
local comp = awful.completion
comp.bashcomp_load("/usr/share/bash-completion/bash_completion")
-- Local libraries.
local tags = require("tags")
local launcher = require("launcher")
local clients = require("clients")
local math_util = assert(loadfile(gears.filesystem.get_configuration_dir().."math.lua"))()

-- Generic key bindings.
local function awesome_permanent_quit()
  ok, msg = touch("/tmp/no_gui")
  if not ok then
    naughty.notify({text = string.format("Cannot create mark file due to `%s`!", msg)})
  else
    awesome.quit()
  end
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
local function artificial_mouse_click(receiver)
  -- print(string.format("Pressing client %i at coords (%i, %i).", receiver.pid, x, y))
  -- local old_coords = mouse.coords()
  awful.spawn("xdotool click 1 click 1 click 1", false)
end

local misc_04 = awful.key({modkey, "Shift"}, "a", function()
  artificial_mouse_click(client.focus)
end, {description = "Autoclicker x3", group = "Misc"})
globalkeys = gears.table.join(globalkeys, misc_04)

-- if machine_identifier ~= "laptop" then
  -- local misc_01 = awful.key({modkey, "Shift"}, "m", function()
  --   awful.spawn("switcher -mon hdmi2")
  -- end, {description = "Switch display to X11", group = "Misc"})
  -- local misc_02 = awful.key({modkey, "Shift"}, "l", function()
  --   awful.spawn("switcher -mon dp -delay 1500 -mon hdmi2")
  -- end, {description = "Clear monitor lockup and switch display to X11", group = "Misc"})
  -- local misc_03 = awful.key({modkey, "Shift"}, "n", function()
  --   awful.spawn("switcher -mon dp -delay 500 -vt 2")
  -- end, {description = "Switch display connection to Weston", group = "Misc"})
  -- globalkeys = gears.table.join(globalkeys, misc_02)
-- end

-- Autoclicker: uniform interval (1.8~2.3s), Gaussian hold duration, tag change cancellation
local autoclick_state = {
  timer = nil,
  release_timer = nil,
  button_pressed = false,
}

local function autoclick_stop(notify_if_not_running)
  if autoclick_state.timer then
    autoclick_state.timer:stop()
    autoclick_state.timer = nil
  elseif notify_if_not_running then
    naughty.notify({
      title = "Autoclicker",
      text = "Autoclicker is not running",
      timeout = 2
    })
    return
  end

  if autoclick_state.release_timer then
    autoclick_state.release_timer:stop()
    autoclick_state.release_timer = nil
  end

  if autoclick_state.button_pressed then
    root.fake_input("button_release", 1)
    autoclick_state.button_pressed = false
  end
end

local function autoclick_press()
  root.fake_input("button_press", 1)
  autoclick_state.button_pressed = true

  local hold_duration = math_util.random_gaussian(0.070, 0.012, 0.040, 0.120)
  autoclick_state.release_timer = gears.timer.start_new(hold_duration, function()
    if autoclick_state.button_pressed then
      root.fake_input("button_release", 1)
      autoclick_state.button_pressed = false
    end
    autoclick_state.release_timer = nil
    return false -- one-shot timer
  end)
end

local function autoclick_start()
  if autoclick_state.timer then
    naughty.notify({
      title = "Autoclicker",
      text = "Autoclicker already running!",
      timeout = 2
    })
    return
  end

  -- Fire initial click immediately
  autoclick_press()

  -- Schedule repeating clicks with uniform distribution (1.8~2.3s)
  local initial_interval = math_util.random_interval(1.8, 2.3)
  autoclick_state.timer = gears.timer({
    timeout = initial_interval,
    callback = function()
      autoclick_press()
      if autoclick_state.timer then
        autoclick_state.timer.timeout = math_util.random_interval(1.8, 2.3)
        autoclick_state.timer:again()
      end
    end
  })
  autoclick_state.timer:start()
end

-- Auto-cancel when switching tags/workspaces
tag.connect_signal("property::selected", function(t)
  if autoclick_state.timer then
    autoclick_stop(false)
  end
end)

local autoclick_start_key = awful.key({modkey, "Shift"}, "m", autoclick_start,
  {description = "Start autoclicker (1.8~2.3s interval)", group = "Misc"})
local autoclick_stop_key = awful.key({modkey, "Shift"}, "n", function() autoclick_stop(true) end,
  {description = "Stop autoclicker", group = "Misc"})
globalkeys = gears.table.join(globalkeys, autoclick_start_key, autoclick_stop_key)

-- Register keybinds.
root.keys(globalkeys)
