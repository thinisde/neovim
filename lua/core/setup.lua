require("remote-sshfs").callback.on_connect_success:add(function(host, mount_dir)
	local name = host.host or host.hostname or "unknown"
	vim.notify("Mounted " .. name .. " at " .. mount_dir)
end)

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function(args)
		if vim.bo[args.buf].filetype == "oil" then
			return
		end
		require("conform").format({ bufnr = args.buf, lsp_fallback = true, timeout_ms = 2000 })
	end,
})

vim.api.nvim_create_autocmd("TermEnter", {
	pattern = "term://*toggleterm#*",
	callback = function()
		vim.keymap.set("t", "<C-t>", function()
			local count = vim.v.count1
			vim.cmd(count .. "ToggleTerm")
		end, { buffer = true, silent = true })
	end,
})
