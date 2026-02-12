---@type Wezterm
local wezterm = require("wezterm")

---@class Wezterm.Global
local g = wezterm.GLOBAL

local presets = require("presets") or {}

local mux = wezterm.mux

local function ensure_workspace_tab_config(window)
	local name = window:active_workspace()

	local tab = window:active_tab()
	local tab_id = tostring(tab:tab_id())

	if g.workspaces == nil then
		g.workspaces = {}
	end

	if g.workspaces[name] == nil then
		g.workspaces[name] = {}
	end

	local workspace_config = g.workspaces[name]

	if workspace_config[tab_id] == nil then
		workspace_config[tab_id] = {}
	end

	return workspace_config[tab_id]
end

local function has_term_pane(window)
	local tab_config = ensure_workspace_tab_config(window)

	return tab_config.term_pane_id ~= nil
end

local function ensure_esencial_panes(window)
	local tab_config = ensure_workspace_tab_config(window)
	local pane = window:active_pane()

	if tab_config.main_pane_id == nil then
		tab_config.main_pane_id = pane:pane_id()
	end

	if tab_config.term_pane_id == nil then
		local term_pane_id = pane:split({
			direction = "Bottom",
			size = 0.2,
		}):pane_id()

		tab_config.term_pane_id = term_pane_id
	end

	return tab_config.main_pane_id, tab_config.term_pane_id
end

local module = {}

function module.switch_to_workspace(window, pane, name, dir)
	local current_workspace = window:active_workspace()
	if current_workspace == name then
		return
	end

	g.previous_workspace = current_workspace

	local params = { name = name }

	if dir ~= nil then
		params.spawn = { cwd = dir }
	end

	window:perform_action(wezterm.action.SwitchToWorkspace(params), pane)
end

function module.choose_workspace(window, pane)
	local workspaces = mux.get_workspace_names()

	local choices = {}
	for i, name in ipairs(workspaces) do
		table.insert(choices, { label = tostring(i) .. ": " .. name })
	end

	window:perform_action(
		wezterm.action.InputSelector({
			title = "workspaces",
			choices = choices,
			fuzzy = true,
			action = wezterm.action_callback(function(_, _, _, label)
				-- NOTE: truncate "i: " that follows the name of the workspace
				label = label:match("^%d+%: (.+)")
				if not label then
					return
				end

				module.switch_to_workspace(window, pane, label, nil)
			end),
		}),
		pane
	)
end

function module.switch_to_prev_workspace(window, pane)
	local current_workspace = window:active_workspace()
	local prev_workspace = g.previous_workspace

	if current_workspace == prev_workspace or prev_workspace == nil then
		return
	end

	module.switch_to_workspace(window, pane, prev_workspace, nil)
end

function module.choose_project(window, pane)
	local dir = presets.projects_dir or "~"

	local projects = wezterm.read_dir(dir)

	local choices = {}
	for _, v in ipairs(projects) do
		local stat_args
		if string.match(wezterm.target_triple, "apple%-darwin") then
			stat_args = { "stat", "-f", "%HT", v }
		else
			stat_args = { "stat", "-c", "%F", v }
		end
		local success, stdout, _ = wezterm.run_child_process(stat_args)

		local _, count = string.gsub(string.lower(stdout), "directory", {})
		if success and count > 0 then
			table.insert(choices, { label = v })
		end
	end

	window:perform_action(
		wezterm.action.InputSelector({
			title = "projects",
			choices = choices,
			fuzzy = true,
			action = wezterm.action_callback(function(_, _, _, label)
				if not label then
					return
				end

				local name = label:match("([^/]+)$")

				module.switch_to_workspace(window, pane, name, label)
			end),
		}),
		pane
	)
end

function module.toggle_terminal(window, _)
	local term_pane_just_created = has_term_pane(window)
	local main_pane_id, term_pane_id = ensure_esencial_panes(window)

	if not term_pane_just_created then
		return
	end

	local active_tab = window:active_tab()

	local main_pane = nil
	local main_pane_zoomed = false

	local term_pane = nil

	for _, info in ipairs(active_tab:panes_with_info()) do
		if info.pane:pane_id() == main_pane_id then
			main_pane = info.pane
			main_pane_zoomed = info.is_zoomed
		end

		if info.pane:pane_id() == term_pane_id then
			term_pane = info.pane
		end
	end

	if main_pane == nil then
		return
	end

	if term_pane == nil then
		return
	end

	if main_pane_zoomed then
		active_tab:set_zoomed(false)
		term_pane:activate()
	else
		main_pane:activate()
		active_tab:set_zoomed(true)
	end
end

return module
