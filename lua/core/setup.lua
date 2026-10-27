vim.api.nvim_create_autocmd("TermEnter", {
	pattern = "term://*toggleterm#*",
	callback = function()
		vim.keymap.set("t", "<C-t>", function()
			local count = vim.v.count1
			vim.cmd(count .. "ToggleTerm")
		end, { buffer = true, silent = true })
	end,
})
