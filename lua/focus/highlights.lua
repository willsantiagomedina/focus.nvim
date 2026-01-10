local M = {}

local function get_hl(name)
	-- Neovim 0.9/0.10 compatibility
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if ok and hl then
		return hl
	end

	-- fallback for older
	local ok2, hl2 = pcall(vim.api.nvim_get_hl_by_name, name, true)
	if ok2 and hl2 then
		return {
			fg = hl2.foreground,
			bg = hl2.background,
			sp = hl2.special,
		}
	end

	return {}
end

local function pick_dim_fg()
	-- We want a “dim” fg that exists in most themes
	local candidates = { "Comment", "LineNr", "NonText" }
	for _, name in ipairs(candidates) do
		local hl = get_hl(name)
		if hl.fg then
			return hl.fg
		end
	end
	return nil
end

function M.ensure()
	-- Base colors from current theme
	local normal = get_hl("Normal")
	local signcol = get_hl("SignColumn")

	local dim_fg = pick_dim_fg()

	-- Create our own dim groups so the effect is visible even if NormalNC is same as Normal
	vim.api.nvim_set_hl(0, "FocusDimNormal", {
		fg = dim_fg or normal.fg,
		bg = normal.bg,
	})

	vim.api.nvim_set_hl(0, "FocusDimSignColumn", {
		fg = dim_fg or signcol.fg or normal.fg,
		bg = signcol.bg or normal.bg,
	})
end

function M.setup_autocmd()
	-- Recompute when colorscheme changes
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			M.ensure()
		end,
	})
end

return M
