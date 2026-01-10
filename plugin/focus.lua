vim.api.nvim_create_user_command("Focus", function()
	require("focus").toggle()
end, {})
