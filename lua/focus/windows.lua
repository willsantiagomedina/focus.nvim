local config = require("focus.config")

local M = {}

local enabled = false
local saved = {}
local autocmd_id = nil

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

-- Apply focus effect to a new window created while focus mode is enabled
local function apply_focus_to_window(win)
	if not enabled then
		return
	end

	local current = vim.api.nvim_get_current_win()

	-- Snapshot the original state of the new window
	if not saved[win] then
		saved[win] = {
			winhighlight = get_win_opt(win, "winhighlight"),
			cursorline = get_win_opt(win, "cursorline"),
		}
	end

	-- Apply focus effect based on whether it's the current window
	if win == current then
		set_win_opt(win, "winhighlight", "")
		set_win_opt(win, "cursorline", config.options.cursorline)
	else
		set_win_opt(win, "winhighlight", "Normal:FocusDim,NormalNC:FocusDim")
		set_win_opt(win, "cursorline", false)
	end
end

-- Setup autocmd to handle windows created while focus mode is enabled
local function setup_autocmd()
	if autocmd_id then
		return
	end

	autocmd_id = vim.api.nvim_create_autocmd({ "WinNew", "WinEnter" }, {
		callback = function()
			if enabled then
				local win = vim.api.nvim_get_current_win()
				apply_focus_to_window(win)
			end
		end,
	})
end

-- Remove autocmd when focus mode is disabled
local function remove_autocmd()
	if autocmd_id then
		vim.api.nvim_del_autocmd(autocmd_id)
		autocmd_id = nil
	end
end

function M.toggle()
	enabled = not enabled
	local current = vim.api.nvim_get_current_win()

	ensure_highlight()

	if enabled then
		-- Setup autocmd to handle new windows while focus mode is enabled
		setup_autocmd()

		-- Enabling: snapshot original state for each window (only if not already saved)
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if not saved[win] then
				saved[win] = {
					winhighlight = get_win_opt(win, "winhighlight"),
					cursorline = get_win_opt(win, "cursorline"),
				}
			end

			if win == current then
				set_win_opt(win, "winhighlight", "")
				set_win_opt(win, "cursorline", config.options.cursorline)
			else
				set_win_opt(win, "winhighlight", "Normal:FocusDim,NormalNC:FocusDim")
				set_win_opt(win, "cursorline", false)
			end
		end
	else
		-- Remove autocmd when disabling
		remove_autocmd()

		-- Disabling: restore original state from snapshots
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if saved[win] then
				set_win_opt(win, "winhighlight", saved[win].winhighlight or "")
				set_win_opt(win, "cursorline", saved[win].cursorline or false)
			end
		end

		-- Clear saved state after restoring
		saved = {}

		-- Force visual refresh to ensure all windows update immediately
		vim.cmd("redraw!")
		
		-- Additional scheduled redraw for stubborn cases
		vim.schedule(function()
			vim.cmd("redraw!")
		end)
	end

	vim.notify("Focus mode " .. (enabled and "ON" or "OFF"))
end

return M
