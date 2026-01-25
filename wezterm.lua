local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	gui_window:maximize()
end)

-- local launch_menu = {}

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

config.font_size = 12.0
config.line_height = 1.0

config.underline_position = -3
config.underline_thickness = 2

-- wezterm.on("update-status", function(window)
--
-- end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.active_pane.title

	local color_scheme = config.resolved_palette
	local bg = wezterm.color.parse(color_scheme.background)
	local fg = wezterm.color.parse(color_scheme.foreground)
	local cwd = tab.active_pane.current_working_dir

	-- if tab.is_active then
	-- 	return {
	-- 		{ Background = { Color = "white" } },
	-- 		{ Foreground = { Color = fg } },
	-- 		{ Text = cwd },
	-- 	}
	-- end
end)

-- Return the tab's current working directory
local function get_cwd(tab)
	local pane = tab.active_pane
	if not pane then
		return ""
	end

	local cwd = pane.current_working_dir
	if not cwd then
		return ""
	end

	return cwd.file_path or ""
end

return config
