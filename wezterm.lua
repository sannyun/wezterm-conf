---@type Wezterm
local wezterm = require("wezterm")

local projects = require("projects")

local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	gui_window:maximize()
end)

---@type Config
local config = wezterm.config_builder()

config.window_decorations = "RESIZE"

config.color_scheme = "Tokyo Night"

config.initial_cols = 120
config.initial_rows = 28

config.font = wezterm.font_with_fallback({
	{
		family = "Fira Code",
		harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero", "ss01", "cv05" },
		weight = "Regular",
	},
	"Symbols Nerd Font",
})

if wezterm.target_triple == "aarch64-apple-darwin" then
	config.font_size = 14.0
else
	config.font_size = 12.0
end

config.line_height = 1.0

config.underline_position = -3
config.underline_thickness = 2

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action_callback(projects.choose_project),
	},
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action_callback(projects.nvim_project),
	},
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY | WORKSPACES" }),
	},
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	{ key = "L", mods = "CTRL", action = wezterm.action.ShowDebugOverlay },
}

local process_icons = {}
process_icons["nvim"] = ""
process_icons["lazygit"] = ""
process_icons["yazi"] = ""

-- Convert arbitrary strings to a unique hex color value
-- Based on: https://stackoverflow.com/a/3426956/3219667
local function string_to_color(str)
	-- Convert the string to a unique integer
	local hash = 0
	for i = 1, #str do
		hash = string.byte(str, i) + ((hash << 5) - hash)
	end
	-- Convert the integer to a unique color
	local hue = (hash & 0x1ff) / 512 * 360
	local saturation = ((hash >> 9) & 255) / 255 * 60
	local c = wezterm.color.from_hsla(hue, saturation, 0.18, 1)
	return c
end

local function get_tab_color(tab_info)
	local active_pane = tab_info.active_pane
	local cwd = active_pane.current_working_dir
	return string_to_color(cwd.file_path)
end

local function calculate_tab_title(tab_info)
	local active_pane = tab_info.active_pane
	local pane_title = active_pane.title
	local title = pane_title

	local process = active_pane.user_vars.WEZTERM_PROG
	if process and #process > 0 then
		local icon = process_icons[process]
		if icon then
			title = string.format("%s %s", icon, pane_title)
		end
	end

	return title
end

local function get_tab_title(tab_info)
	local title = tab_info.tab_title
	if title and #title > 0 then
		return title
	end

	return calculate_tab_title(tab_info)
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = get_tab_title(tab)

	local color_scheme = config.resolved_palette
	local fg = wezterm.color.parse(color_scheme.foreground)

	if tab.is_active then
		return {
			{ Background = { Color = get_tab_color(tab) } },
			{ Foreground = { Color = fg } },
			{ Text = title },
		}
	end

	return title
end)

return config
