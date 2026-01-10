local config = require("focus.config")

local M = {}

local enabled = false
local saved = {}

-- create dim background highlight (visible in ALL themes)
local function ensure_highlight()
	vim.api.nvim_set_hl(0, "FocusDim", {
		bg = config.options.dim_bg,
	})
end

local function get_win_opt(win, opt)
	return vim.api.nvim_get_option_value(opt, { win = win })
end

local function set_win_opt(win, opt, value)
	vim.api.nvim_set_option_value(opt, value, { win = win })
end

function M.toggle()
	enabled = not enabled
	local current = vim.api.nvim_get_current_win()

	ensure_highlight()

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		saved[win] = {
			winhighlight = get_win_opt(win, "winhighlight"),
			cursorline = get_win_opt(win, "cursorline"),
		}

		if enabled then
			if win == current then
				set_win_opt(win, "winhighlight", "")
				set_win_opt(win, "cursorline", config.options.cursorline)
			else
				set_win_opt(win, "winhighlight", "Normal:FocusDim,NormalNC:FocusDim")
				set_win_opt(win, "cursorline", false)
			end
		else
			set_win_opt(win, "winhighlight", saved[win].winhighlight or "")
			set_win_opt(win, "cursorline", saved[win].cursorline or false)
		end
	end

	-- Force visual refresh to ensure all windows update immediately
	vim.cmd("redraw!")

	vim.notify("Focus mode " .. (enabled and "ON" or "OFF"))
end

return M
