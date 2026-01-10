local M = {}

M.defaults = {
	dim_bg = "#1c1c1c",
	cursorline = true,
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

return M
