local windows = require("focus.windows")

local M = {}

function M.setup(opts)
	require("focus.config").setup(opts)
	windows.setup_autocmd()

	if require("focus.config").options.enable_on_startup then
		windows.enable({ silent = true })
	end
end

function M.toggle()
	windows.toggle()
end

function M.enable()
	windows.enable()
end

function M.disable()
	windows.disable()
end

return M
