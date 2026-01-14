local M = {}

local config = require("focus.config")
local state = require("focus.state")

local function hl_get(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function hl_set(name, val)
	vim.api.nvim_set_hl(0, name, val)
end

local function get_winhighlight(win)
	return vim.api.nvim_win_get_option(win, "winhighlight")
end

local function set_winhighlight(win, value)
	vim.api.nvim_win_set_option(win, "winhighlight", value)
end

local function resolve_bg(value)
	if type(value) ~= "string" then
		return value
	end

	if value == "NONE" or value == "none" then
		return "NONE"
	end

	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = value, link = true })
	if ok and hl and hl.bg then
		return hl.bg
	end

	return value
end

local function color_to_rgb(color)
	if type(color) == "string" then
		if not color:match("^#%x%x%x%x%x%x$") then
			return nil
		end
		color = tonumber(color:sub(2), 16)
	end

	if type(color) ~= "number" then
		return nil
	end

	local r = math.floor(color / 65536) % 256
	local g = math.floor(color / 256) % 256
	local b = color % 256
	return r, g, b
end

local function blend_with_black(color, amount)
	if amount <= 0 then
		return color
	end
	if amount >= 1 then
		return "#000000"
	end

	local r, g, b = color_to_rgb(color)
	if not r then
		return nil
	end

	r = math.floor(r * (1 - amount))
	g = math.floor(g * (1 - amount))
	b = math.floor(b * (1 - amount))
	return string.format("#%02x%02x%02x", r, g, b)
end

local function resolve_dim_bg(opts)
	if opts.inactive_bg then
		return resolve_bg(opts.inactive_bg)
	end

	if not opts.dim_amount then
		return nil
	end

	local base_bg = resolve_bg(opts.active_bg) or hl_get("Normal").bg
	if base_bg == "NONE" then
		return nil
	end

	return blend_with_black(base_bg, opts.dim_amount)
end

local function ensure_saved_winhighlight(win)
	if state.saved_winhighlight[win] == nil then
		state.saved_winhighlight[win] = get_winhighlight(win)
	end
end

local function build_dim_group(name, inactive_bg)
	local base = hl_get(name)
	if not base or vim.tbl_isempty(base) then
		base = hl_get("Normal")
	end
	local dim = vim.tbl_extend("force", {}, base)
	dim.bg = inactive_bg
	return dim
end

local function apply_focus()
	local opts = config.options
	local inactive_bg = resolve_dim_bg(opts)
	local active_bg = resolve_bg(opts.active_bg)

	if inactive_bg then
		hl_set("FocusDimNormal", build_dim_group("Normal", inactive_bg))
		hl_set("FocusDimSignColumn", build_dim_group("SignColumn", inactive_bg))
		hl_set("FocusDimEndOfBuffer", build_dim_group("EndOfBuffer", inactive_bg))
		hl_set("FocusDimNormalFloat", build_dim_group("NormalFloat", inactive_bg))
	end

	if active_bg then
		hl_set("FocusActiveNormal", build_dim_group("Normal", active_bg))
	end
end

local function build_winhighlight(base, mapping)
	if not mapping or mapping == "" then
		return base
	end
	if not base or base == "" then
		return mapping
	end
	return base .. "," .. mapping
end

local function update_winhighlight()
	local opts = config.options
	local current = vim.api.nvim_get_current_win()
	local wins = vim.api.nvim_tabpage_list_wins(0)

	for _, win in ipairs(wins) do
		if vim.api.nvim_win_is_valid(win) then
			ensure_saved_winhighlight(win)
			local base = state.saved_winhighlight[win]
			local mapping = ""

			if win == current then
				if opts.active_bg then
					mapping = "Normal:FocusActiveNormal"
				end
			else
				if opts.inactive_bg then
					mapping = "Normal:FocusDimNormal,SignColumn:FocusDimSignColumn,EndOfBuffer:FocusDimEndOfBuffer,NormalFloat:FocusDimNormalFloat"
				end
			end

			set_winhighlight(win, build_winhighlight(base, mapping))
		end
	end
end
end

local function is_focusable_window(win)
	local cfg = vim.api.nvim_win_get_config(win)
	return cfg.relative == ""
end

local function focusable_window_count()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	local count = 0
	for _, win in ipairs(wins) do
		if is_focusable_window(win) then
			count = count + 1
		end
	end
	return count
end

local function auto_update()
	if not config.options.auto_enable then
		return
	end

	if focusable_window_count() > 1 then
		M.enable({ silent = true })
	else
		M.disable({ silent = true })
	end
end

function M.enable(opts)
	if state.enabled then
		return
	end

	state.enabled = true
	apply_focus()
	update_winhighlight()
	vim.cmd("redraw!")

	if not (opts and opts.silent) then
		vim.notify("Focus mode ON")
	end
end

function M.disable(opts)
	if not state.enabled then
		return
	end

	for win, value in pairs(state.saved_winhighlight) do
		if vim.api.nvim_win_is_valid(win) then
			set_winhighlight(win, value)
		end
	end
	state.saved_winhighlight = {}
	state.enabled = false
	vim.cmd("redraw!")

	if not (opts and opts.silent) then
		vim.notify("Focus mode OFF")
	end
end

function M.toggle()
	if state.enabled then
		M.disable()
	else
		M.enable()
	end
end

function M.reapply()
	if not state.enabled then
		return
	end

	apply_focus()
	update_winhighlight()
	vim.cmd("redraw!")
end

function M.setup_autocmd()
	local group = vim.api.nvim_create_augroup("FocusNvim", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			M.reapply()
		end,
	})

	vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "WinClosed", "TabEnter" }, {
		group = group,
		callback = function()
			auto_update()
			if state.enabled then
				update_winhighlight()
			end
		end,
	})

	auto_update()
end

return M
