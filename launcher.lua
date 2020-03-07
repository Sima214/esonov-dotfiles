local api = {}

-- WM libs.
local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local screen = awful.screen
local spawn = awful.spawn.spawn
-- 'Master'
local tags = require("tags")

-- Client grabbing internal state.
local waiting_client_id = nil
local waiting_tag_object = nil
local waiting_timestamp = os.time()

-- Tags private extensions.
local function tags_set_launcher_state(o, count, tm)
  o.spawning_index = count
  o.spawn_timestamp = tm
end

local function tags_clear_launcher_state(o)
  tags_set_launcher_state(o, nil, nil)
end

-- Checks if there are any enabled commands.
local function tags_launcher_available(o)
  if o.spawn_cmd then
    for _, cmd_obj in ipairs(o.spawn_cmd) do
      if cmd_obj.enabled then
        return true
      end
    end
  end
  return false
end

-- Launches all enabled commands.
local function tags_launcher_launch(o)
  o.instance.screen.taglist:_redraw()
  tags_set_launcher_state(o, 0, os.time())
  local function recursive_spawn_chain()
    for next_index = o.spawning_index+1, #o.spawn_cmd do
      cmd_obj = o.spawn_cmd[next_index]
      if cmd_obj.enabled then
        tags_set_launcher_state(o, next_index, os.time())
        local cmd = cmd_obj.shell and {awful.util.shell, "-c", cmd_obj.cmd} or cmd_obj.cmd
        spawn(cmd, true, recursive_spawn_chain)
        return
      end
    end
    -- No more commands to spawn, reset state.
    tags_clear_launcher_state(o)
    api.select_tag(o.index, true, true)
  end
  recursive_spawn_chain()
end

-- Autostart handler.
local function autostart()
  for _, tag_obj in ipairs(tags.registry) do
    if tag_obj.auto_spawn and tags_launcher_available(tag_obj) and #tag_obj.instance:clients() == 0 then
      tags_launcher_launch(tag_obj)
    end
  end
end

-- Returns true if the request was valid and accepted.
function api.select_tag(tag_id, quiet, noautostart)
  local tag_obj = tags.registry[tag_id]
  local tag = tag_obj.instance
  -- Logger
  logger = function(msg)
    if not quiet then
      naughty.notify({text = msg})
    end
  end
  -- Can we switch to the tag NOW?
  if tag_obj.locked then
    -- Test lock.
    logger(string.format("Tag `%s` is locked!", tag_obj.name))
    return false
  elseif #tag:clients() ~= 0 then
    -- Test if tag has any clients, if it has switch to it.
    tags_clear_launcher_state(tag_obj)
    tag:view_only()
    return true
  elseif tag_obj.spawning_index then
    if os.difftime(os.time(), tag_obj.spawn_timestamp) <= tags_spawn_timeout_sec then
      logger(string.format("Already waiting on `%s`!", tag_obj.name))
      return false
    else
      -- Timeout.
      logger(string.format("Timed out while waiting on `%s`!", tag_obj.name))
      tags_clear_launcher_state(tag_obj)
    end
  end
  -- Else use the launcher.
  if not noautostart then
    if tags_launcher_available(tag_obj) then
      tags_launcher_launch(tag_obj)
      return true
    else
      -- There is nothing else to do, so just log this.
      logger(string.format("No enabled commands for `%s`!", tag_obj.name))
      return false
    end
  end
  return false
end

function api.register_taglist(wtl)
  wtl:connect_signal("button::release", function(w, lx, ly, button, mods, r)
    local tag = w.hovered_tag
    if #mods == 0 and tag then
      -- Left mouse click selects.
      if button == 1 then
        api.select_tag(tag.index)
      end
    end
  end)
end

function api.register_buttons(keyboard)
  -- Register auto start handler.
  awesome.connect_signal("startup", autostart)
  for _, obj in ipairs(tags.registry) do
    local new_key = awful.key({modkey}, obj.key, function()
      api.select_tag(obj.index)
    end,
    {description=string.format("Switch to %s", obj.name), group="Tag"})
    keyboard = gears.table.join(keyboard, new_key)
  end
  local tag_left_key = awful.key({modkey}, "Left",
    function()
      local current = tags.registry[awful.screen.focused().selected_tag.name]
      local previous_index = ((current.index + (#tags.registry - 2)) % #tags.registry) + 1
      while previous_index ~= current.index do
        if api.select_tag(previous_index, true, true) then
          return
        end
        -- Prepare for next iteration.
        previous_index = ((previous_index + (#tags.registry - 2)) % #tags.registry) + 1
      end
      end,
      {description = "Switch to the previous active tag.", group = "Tag"})
  local tag_right_key = awful.key({modkey}, "Right",
    function()
      local current = tags.registry[awful.screen.focused().selected_tag.name]
      local next_index = (current.index % #tags.registry) + 1
      while next_index ~= current.index do
        if api.select_tag(next_index, true, true) then
          return
        end
        -- Prepare for next iteration.
        next_index = (next_index % #tags.registry) + 1
      end
    end,
    {description = "Switch to the next active tag.", group = "Tag"})
  
  keyboard = gears.table.join(keyboard, tag_left_key, tag_right_key)
  -- Return new bindings.
  return keyboard
end

return api
