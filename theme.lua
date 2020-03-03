-- Awesome theme for esonov distro.
local gears = require("gears")
local naughty_config = require("naughty").config
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local theme = {}

-- General look and feel.
theme.font = "Roboto 10"

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
theme.prompt_font = "Hack 11"

-- Variables set for theming notifications:
theme.notification_font = "Droid Sans 12"
theme.notification_bg = "#685f77"
theme.notification_fg = "#e0dfe2"
theme.notification_width = nil
theme.notification_height = nil
theme.notification_margin = nil
theme.notification_border_color = "#685f77"
theme.notification_border_width = dpi(3)
theme.notification_shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 4) end
theme.notification_icon_size = 48
theme.notification_opacity = 0.92
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

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
-- TODO: make it work.
theme.icon_theme = "Papirus-Dark"

-- Bar layout.
theme.bar_layout = {
    close_image = icons_path.."close.png",
    close_hover_image = icons_path.."close_hover.png",
    tasklist_height = dpi(14),
    tasklist_icon_margin = {left = dpi(2), right = dpi(3), up = 1, bottom = 1},
    tasklist_title_margin = {left = dpi(3), right = dpi(4), up = 0, bottom = 0},
    tasklist_close_margin = {left = dpi(4), right = dpi(2), up = 0, bottom = 0},
    tasklist_close_button_image = icons_path.."tasklist_close.png",
    tasklist_close_button_hover_image = icons_path.."tasklist_close_hover.png",
    tasklist_close_button_size = dpi(14)
}

return theme
