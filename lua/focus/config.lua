local M = {}

M.defaults = {
	enable_on_startup = false,
	inactive_bg = "#1c1c1c",
	active_bg = false,
	dim_amount = 0.25,
	auto_enable = false,
}

M.options = {}

function M.setup(opts)
	opts = opts or {}
	if opts.dim_bg and not opts.inactive_bg then
		opts.inactive_bg = opts.dim_bg
	end
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts)
end

return M
