local windows = require("focus.windows")

local M = {}

function M.setup(opts)
	require("focus.config").setup(opts)
end

function M.toggle()
	windows.toggle()
end

return M
