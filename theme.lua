-- Awesome theme for esonov distro.
local gears = require("gears")
local naughty_config = require("naughty").config
local xresources = require("beautiful.xresources")
local beautiful = require("beautiful")
local gtk = beautiful.gtk.get_theme_variables()
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

-- Client settings
theme.useless_gap = 0
theme.border_width = 0
theme.border_normal = theme.bg_normal
theme.border_focus = theme.bg_focus
theme.border_marked = theme.bg_focus
theme.tasklist_plain_task_name = true

-- Titlebar (for dialogs)
theme.titlebar_bg = "#313131cc"
theme.titlebar_height = dpi(18)
theme.titlebar_font = "Roboto 9"
theme.titlebar_shape = function(cr, w, h) gears.shape.partially_rounded_rect(cr, w, h, true, true, false, false, theme.titlebar_height) end

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

-- Define the icon theme for application icons.
-- If not set then the icons from /usr/share/icons and /usr/share/icons/hicolor will be used.
-- Used only by the menubar as far as I know.
theme.icon_theme = "Papirus-Dark"

-- Bar layout.
theme.bar_layout = {
    close_image = icons_path.."close.png",
    close_hover_image = icons_path.."close_hover.png",
    tasklist_height = dpi(14),
    tasklist_icon_margin = {left = dpi(2), right = dpi(3), up = 1, bottom = 1},
    tasklist_title_margin = {left = dpi(3), right = dpi(4), up = 0, bottom = dpi(2)},
    tasklist_close_margin = {left = dpi(4), right = dpi(2), up = 0, bottom = 0},
    tasklist_close_button_image = icons_path.."tasklist_close.png",
    tasklist_close_button_hover_image = icons_path.."tasklist_close_hover.png",
    tasklist_close_button_size = dpi(14)
}

-- Tag colors and layout
theme.tag = {layout = {}, colors = {inactive = {}, active = {}, highlight = {}, bubble = {}}}

theme.tag.layout.icon_size = dpi(24)
theme.tag.layout.padding = 1
theme.tag.layout.spacing = dpi(8)
theme.tag.layout.halo_scale = 1.08
theme.tag.layout.bubble_offset_x = dpi(20)
theme.tag.layout.bubble_offset_y = dpi(20)
theme.tag.layout.bubble_text_offset_x = dpi(17)
theme.tag.layout.bubble_text_offset_y = dpi(15)
theme.tag.layout.bubble_radius = 5
theme.tag.layout.bubble_font = "Hack Bold 6"
theme.tag.layout.default_cursor = "left_ptr"
theme.tag.layout.hover_cursor = "hand1"
theme.tag.layout.invalid_cursor = "left_ptr"
theme.tag.layout.locked_cursor = "circle"

-- Same as the background.
theme.tag.colors.inactive["000000"] = "#2e293a"
theme.tag.colors.active["000000"] = "#2e293a"
theme.tag.colors.highlight["000000"] = "#2e293a"
-- The base color.
theme.tag.colors.inactive["ffffff"] = "#8c80a4"
theme.tag.colors.active["ffffff"] = "#cac8d1"
theme.tag.colors.highlight["ffffff"] = "#cac8d1"
-- Highlight color pattern #1.
-- It is invisible when inactive, and pulsating when urgent.
theme.tag.colors.inactive["ff0000"] = "#2e293a"
theme.tag.colors.active["ff0000"] = "#4629bb"
theme.tag.colors.highlight["ff0000"] = "#2a00c1"
-- Highlight color pattern #2.
-- Visible even when inactive, but darker.
theme.tag.colors.inactive["00ff00"] = "#292089"
theme.tag.colors.active["00ff00"] = "#4629bb"
theme.tag.colors.highlight["00ff00"] = "#2a00c1"
-- Highlight color pattern #3.
-- Constant color(may add blur when urgent), just a bit darker when inactive.
theme.tag.colors.inactive["0000ff"] = "#292089"
theme.tag.colors.active["0000ff"] = "#4629bb"
theme.tag.colors.highlight["0000ff"] = "#4629bb"

theme.tag.colors.bubble.locked = "#ffd700aa"
theme.tag.colors.bubble.waiting = "#d6820699"
theme.tag.colors.bubble.inactive = "#2e293a66"
theme.tag.colors.bubble.active = "#5b4965cc"
theme.tag.colors.bubble.selected = "#362f43ff"
theme.tag.colors.bubble.font = {
    active="#ffffffaa",
    selected="#ffffff99"
}

theme.tag.colors.halo = {
    inactive="#8c80a4cc",
    active="#cac8d1aa"
}

theme.weather = {
    icons = {
        path = gears.filesystem.get_configuration_dir().."icons/weather/"
    },
    side_text = {
        font = "Roboto 6.5",
        margin_left = dpi(4),
        margin_right = dpi(5),
        margin_top = dpi(1),
    },
    separator = {
        width = dpi(3),
        color = "#cac8d1"
    }
}

return theme
