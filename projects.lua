---@type Wezterm
local wezterm = require("wezterm")

local module = {}

local function project_dir()
	wezterm.log_info(wezterm.config_dir)
	local success, stdout, _ =
		wezterm.run_child_process({ "cat", string.format("%s/%s", wezterm.config_dir, "PROJECTS_DIR") })

	if success and #stdout > 0 then
		return stdout:match("%c*([%w//]+)%c*$")
	else
		return "~"
	end
end

function module.choose_project(window, pane)
	local dir = project_dir()
	wezterm.log_info(dir)

	local projects = wezterm.read_dir(dir)

	local choices = {}
	for _, v in ipairs(projects) do
		local success, stdout, _ = wezterm.run_child_process({ "stat", "-c", "%F", v })

		local _, count = string.gsub(stdout, "directory", {})
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

				window:perform_action(
					wezterm.action.SwitchToWorkspace({
						name = name,
						spawn = { cwd = label },
					}),
					pane
				)
			end),
		}),
		pane
	)
end

function module.nvim_project(_, pane)
	pane:split({ direction = "Top", size = 0.8, args = { "nvim" } })
end

return module
