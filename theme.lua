-- Awesome theme for esonov distro.
local gears = require("gears")
local naughty_config = require("naughty").config
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme = {}

-- General look and feel.
theme.font = "Roboto 9.5"

theme.bg_normal = "#2e293a"
theme.bg_focus = "#3d354b"
theme.bg_urgent = "#481565"
theme.bg_minimize = "#2e293a"
theme.bg_systray = "#2e293a"

theme.fg_normal = "#cac8d1"
theme.fg_focus = "#dcdae0"
theme.fg_urgent = "#dcdae0"
theme.fg_minimize = "#cac8d1"

theme.useless_gap = 0
theme.border_width = 0
theme.border_normal = "#cc8080"
theme.border_focus = "#cc8080"
theme.border_marked = "#cc8080"

-- Prompt box theme.
theme.prompt_font = "Hack 14"

-- Variables set for theming notifications:
theme.notification_font = "Droid Sans 15"
theme.notification_bg = "#685f77"
theme.notification_fg = "#e0dfe2"
-- TODO: Fix border shapes.
theme.notification_width = nil
theme.notification_height = nil
theme.notification_margin = nil
theme.notification_border_color = "#685f77"
theme.notification_border_border_width = 2
theme.notification_icon_size = 48
theme.notification_border_shape = gears.shape.rounded_bar
theme.notification_border_opacity = nil
-- Fix colors of presets notification styles.
naughty_config.presets.critical.bg = "#961528"
naughty_config.presets.critical.fg = theme.notification_fg
naughty_config.presets.ok.bg = "#206128"
naughty_config.presets.ok.fg = theme.notification_fg
naughty_config.presets.info.bg = "#2015a2"
naughty_config.presets.info.fg = theme.notification_fg
naughty_config.presets.warn.bg = "#965a28"
naughty_config.presets.warn.fg = theme.notification_fg

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = icons_path .. "outline_arrow_right.png"
-- Mostly irrelevant.
theme.menu_height = dpi(16)
theme.menu_width = dpi(128)

-- Wallpaper.
gears.wallpaper.set(theme.bg_normal)

-- Icon definitions.
local themes_path = awesome.themes_path .. "/"

theme.titlebar_close_button_normal = close_icon_path
theme.titlebar_close_button_focus = close_icon_path

theme.titlebar_maximized_button_normal_inactive = themes_path .. "default/titlebar/maximized_normal_inactive.png"
theme.titlebar_maximized_button_focus_inactive = themes_path .. "default/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_active = themes_path .. "default/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_active = themes_path .. "default/titlebar/maximized_focus_active.png"

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
-- TODO: make it work better.
theme.icon_theme = "Papirus-Dark"

return theme
