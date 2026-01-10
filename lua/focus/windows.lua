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

	-- WinNew fires when a new window is created
	-- We handle it to snapshot and apply focus to new windows
	autocmd_id = vim.api.nvim_create_autocmd("WinNew", {
		callback = function(args)
			if enabled then
				-- Use vim.schedule to ensure window is fully initialized
				vim.schedule(function()
					-- Get all current windows and find the newest one (not in saved)
					for _, win in ipairs(vim.api.nvim_list_wins()) do
						if not saved[win] then
							apply_focus_to_window(win)
							break
						end
					end
				end)
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
		-- We iterate over all windows and restore those that have saved state
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if saved[win] then
				set_win_opt(win, "winhighlight", saved[win].winhighlight or "")
				set_win_opt(win, "cursorline", saved[win].cursorline or false)
			end
		end

		-- Clear saved state after restoring
		-- This also cleans up state for any windows that were closed while focus was enabled
		saved = {}

		-- Force visual refresh to ensure all windows update immediately
		-- Scheduled redraw ensures the UI updates even if windows are not yet fully rendered
		vim.schedule(function()
			vim.cmd("redraw!")
		end)
	end

	vim.notify("Focus mode " .. (enabled and "ON" or "OFF"))
end

return M
