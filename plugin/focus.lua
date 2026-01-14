vim.api.nvim_create_user_command("Focus", function()
	require("focus").toggle()
end, {})

vim.api.nvim_create_user_command("FocusEnable", function()
	require("focus").enable()
end, {})

vim.api.nvim_create_user_command("FocusDisable", function()
	require("focus").disable()
end, {})
