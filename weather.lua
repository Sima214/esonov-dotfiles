-- weather.lua
-- Provides a reusable weather widget generator for AwesomeWM

local api = {}

-- WM libs.
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")

-- 3rd party libs.
local json = require ("dkjson")

local function fetch_data_async(cb)
  local request_uri = string.format(
    "%s?appid=%s&id=%d&units=%s",
    weather_config.endpoint,
    weather_config.api_key,
    weather_config.city_id,
    weather_config.units
  )
  local cmd = {"curl", "--max-time", "15", request_uri}
  awful.spawn.easy_async(cmd, function(stdout, stderr, exitreason, exitcode)
    if exitreason == "exit" and exitcode == 0 then
      local wdat, pos, err = json.decode(stdout)
      if err then
        print("weather data parse error!")
        print(stdout)
      else
        if wdat.cod == 200 then
          local local_timestamp = wdat.dt
          local ui_dat = {
            icon_id = wdat.weather[1].icon,
            description = wdat.weather[1].description,
            temperature = string.format("%2d°C", math.floor(wdat.main.temp)),
            wind_speed = string.format("%.1f m/s", wdat.wind.speed),
            humidity = string.format("%d %%", math.floor(wdat.main.humidity)),
            last_update = os.date("%Y-%m-%d %H:%M:%S", local_timestamp)
          }
          cb(ui_dat)
        else
          print(string.format("weather data request failed with code %d", wdat.cod))
          if wdat.message then
            print(wdat.message)
          end
        end
      end
    else
      local cmd_full = ">>> "
      for _, v in ipairs(cmd) do
        cmd_full = cmd_full.." "..v
      end
      print(cmd_full)
      print(stderr)
      print(stdout)
      print(string.format("curl request for weather data failed with %s:%d", exitreason, exitcode))
    end
  end)
end

-- Generate a weather widget for a given screen (scr)
function api.gen_widget(scr, bar_height)
  -- Create widgets
  local theme = beautiful.get().weather

  local icon = wibox.widget {
    widget = wibox.widget.imagebox,
    resize = true,
  }

  local temp = wibox.widget {
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center",
    ellipsize = "end",
  }

  local wind = wibox.widget {
    widget = wibox.widget.textbox,
    font = theme.side_text.font,
    align = "center",
    valign = "center",
    ellipsize = "end",
  }

  local humidity = wibox.widget {
    widget = wibox.widget.textbox,
    font = theme.side_text.font,
    align = "center",
    valign = "center",
    ellipsize = "end",
  }

  -- Wrap the icon in a constraint so it never exceeds the bar height
  local icon_wrap = wibox.container.constraint(icon, "max", nil, bar_height)

  -- Combine into a fixed‑horizontal layout (so it shrinks to its contents)
  local sep = wibox.widget {
    orientation  = "vertical",
    forced_width   = theme.separator.width,
    forced_height  = bar_height,
    color      = theme.separator.color,
    widget     = wibox.widget.separator,
  }
  local widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    sep,
    icon_wrap,
    temp,
    {
      widget = wibox.container.margin,
      left = theme.side_text.margin_left,
      right = theme.side_text.margin_right,
      { -- group wind+humidity vertically
        layout = wibox.layout.fixed.vertical,
        spacing = 0,
        {
          widget = wibox.container.margin,
          top = theme.side_text.margin_top,
          wind
        },
        humidity,
      }
    },
    sep
  }

  -- Tooltip for detailed description on icon hover
  local desc_tooltip = awful.tooltip {
    objects = { icon },
    mode = "outside",
    align = "bottom_left",
    text = "..."
  }

  -- Tooltip for last update time on center and right sections
  local update_tooltip = awful.tooltip {
    objects = { temp, wind, humidity },
    mode = "outside",
    align = "bottom_left",
    text = "..."
  }

  -- Update function to refresh widget data.
  function widget._update()
    fetch_data_async(function(data)
      widget._data = data
      local icon_path = theme.icons.path..data.icon_id..".png"
      icon:set_image(icon_path)
      temp:set_text(data.temperature)
      wind:set_text(data.wind_speed)
      humidity:set_text(data.humidity)
      desc_tooltip:set_text(data.description)
      update_tooltip:set_text(data.last_update)
    end)

    return true
  end

  -- Clicking any part forces an update
  for _, w in ipairs({ icon, temp, wind, humidity }) do
    w:connect_signal("button::press", function(_, _, _, btn)
      if btn == 1 then
        widget._update()
        -- Restart timer's counter after manual intervention.
        widget._timer:again()
      end
    end)
  end

  -- Timer, weak to allow garbage collecting.
  widget._timer = gears.timer.weak_start_new(weather_config.update_interval, widget._update)
  -- Initial fetch.
  widget._update()

  return widget
end

return api
