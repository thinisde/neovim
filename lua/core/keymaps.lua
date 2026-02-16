-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

local opts = { noremap = true, silent = true }

-- Undo files
vim.keymap.set("i", "<C-z>", "<cmd> u <CR>", opts)
vim.keymap.set("n", "U", "<C-r>", opts)

-- Save file
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", opts)
vim.keymap.set("i", "<C-s>", "<cmd> w <CR><Esc>", opts)

-- Save file without auto-formatting
vim.keymap.set("n", "<leader>sn", "<cmd>noautocmd w <CR>", opts)

-- Delete single character without copying into register
vim.keymap.set("n", "x", '"_x', opts)

-- Vertical scroll and center
vim.keymap.set("n", "<C-d>", "Hzz", opts)
vim.keymap.set("n", "<C-i>", "Lzz", opts)

-- Find and center
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)

-- Resize with arrows
vim.keymap.set("n", "<Up>", ":resize -2<CR>", opts)
vim.keymap.set("n", "<Down>", ":resize +2<CR>", opts)
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", opts)
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", opts)

-- Window management
vim.keymap.set("", "<leader>pv", vim.cmd.Ex, opts)

-- Toggle line wrapping
vim.keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", opts)

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- VimTeX group for which-key
vim.keymap.set("n", "<localleader>l", "<Nop>", { silent = true, desc = "+vimtex" })

-- LSP buffer-local keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, {
				buffer = event.buf,
				silent = true,
				desc = "LSP: " .. desc,
			})
		end

		vim.keymap.set("n", "gd", function()
			vim.lsp.buf.definition()
		end, opts)
		vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover()
		end, opts)
		vim.keymap.set("n", "<leader>ws", function()
			vim.lsp.buf.workspace_symbol()
		end, opts)
		vim.keymap.set("n", "<leader>vca", function()
			vim.lsp.buf.code_action()
		end, opts)
		vim.keymap.set("n", "<leader>vrr", function()
			vim.lsp.buf.references()
		end, opts)
		vim.keymap.set("n", "<leader>vrn", function()
			vim.lsp.buf.rename()
		end, opts)
		vim.keymap.set("i", "<C-h>", function()
			vim.lsp.buf.signature_help()
		end, opts)

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
			map("<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
			end, "[T]oggle Inlay [H]ints")
		end
	end,
})

-------------------------------------------------------------------------------
-- Xcodebuild Keymaps
-------------------------------------------------------------------------------

vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", opts)
vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", opts)
vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", opts)
vim.keymap.set("n", "<leader>xq", function()
	local ok, telescope_builtin = pcall(require, "telescope.builtin")
	if ok then
		telescope_builtin.quickfix()
		return
	end
	vim.cmd("copen")
end, opts)
vim.keymap.set("n", "<leader>xx", "<cmd>XcodebuildQuickfixLine<cr>", opts)
vim.keymap.set("n", "<leader>xa", "<cmd>XcodebuildCodeActions<cr>", opts)

-------------------------------------------------------------------------------
-- Telescope Keymaps
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader><space>", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.find_files()
	end
end, opts)

vim.keymap.set("n", "<C-p>", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.git_files()
	end
end, opts)

vim.keymap.set("n", "<leader>pws", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.grep_string({ search = vim.fn.expand("<cword>") })
	end
end, opts)

vim.keymap.set("n", "<leader>pWs", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.grep_string({ search = vim.fn.expand("<cWORD>") })
	end
end, opts)

vim.keymap.set("n", "<leader>ps", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.grep_string({ search = vim.fn.input("Grep > ") })
	end
end, opts)

vim.keymap.set("n", "<leader>vh", function()
	local ok, builtin = pcall(require, "telescope.builtin")
	if ok then
		builtin.help_tags()
	end
end, opts)

-------------------------------------------------------------------------------
-- Trouble Keymaps
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader>tt", function()
	local ok, trouble = pcall(require, "trouble")
	if ok then
		trouble.toggle("diagnostics")
	end
end, opts)

vim.keymap.set("n", "[t", function()
	local ok, trouble = pcall(require, "trouble")
	if ok then
		trouble.previous({ mode = "diagnostics", skip_groups = true, jump = true })
	end
end, opts)

vim.keymap.set("n", "]t", function()
	local ok, trouble = pcall(require, "trouble")
	if ok then
		trouble.next({ mode = "diagnostics", skip_groups = true, jump = true })
	end
end, opts)

-------------------------------------------------------------------------------
-- Fugitive Keymaps
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader>gs", "<cmd>Git<CR>", opts)
vim.keymap.set("n", "gu", "<cmd>diffget //2<CR>", opts)
vim.keymap.set("n", "gh", "<cmd>diffget //3<CR>", opts)

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("user-fugitive-keymaps", { clear = true }),
	pattern = "fugitive",
	callback = function(event)
		local fugitive_opts = { buffer = event.buf, remap = false, silent = true }

		vim.keymap.set("n", "<leader>p", function()
			vim.cmd.Git("push")
		end, fugitive_opts)

		vim.keymap.set("n", "<leader>P", function()
			vim.cmd.Git({ "pull", "--rebase" })
		end, fugitive_opts)

		vim.keymap.set("n", "<leader>t", ":Git push -u origin ", fugitive_opts)
	end,
})

-------------------------------------------------------------------------------
-- Undotree Keymap
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<CR>", opts)

-------------------------------------------------------------------------------
-- Zen Mode Keymaps
-------------------------------------------------------------------------------
vim.keymap.set("n", "<leader>zz", function()
	local ok, zen = pcall(require, "zen-mode")
	if not ok then
		return
	end

	zen.setup({
		window = {
			width = 90,
			options = {},
		},
	})
	zen.toggle()
	vim.wo.wrap = false
	vim.wo.number = true
	vim.wo.rnu = true
end, opts)

vim.keymap.set("n", "<leader>zZ", function()
	local ok, zen = pcall(require, "zen-mode")
	if not ok then
		return
	end

	zen.setup({
		window = {
			width = 80,
			options = {},
		},
	})
	zen.toggle()
	vim.wo.wrap = false
	vim.wo.number = false
	vim.wo.rnu = false
	vim.opt.colorcolumn = "0"
end, opts)

-- Harpon keybinds

vim.keymap.set("n", "<leader>A", function()
	require("harpoon"):list():prepend()
end)
vim.keymap.set("n", "<leader>a", function()
	require("harpoon"):list():add()
end)
vim.keymap.set("n", "<leader>e", function()
	local ok, harpoon = pcall(require, "harpoon")
	if not ok then
		return
	end
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon quick menu" })

vim.keymap.set("n", "<C-h>", function()
	require("harpoon"):list():select(1)
end)
vim.keymap.set("n", "<C-t>", function()
	require("harpoon"):list():select(2)
end)
vim.keymap.set("n", "<C-n>", function()
	require("harpoon"):list():select(3)
end)
vim.keymap.set("n", "<C-b>", function()
	require("harpoon"):list():select(4)
end)

-- Terminal
--
vim.keymap.set({ "n", "i", "t" }, "<C-\\>", function()
	local count = vim.v.count1
	vim.cmd(count .. "ToggleTerm")
end, { silent = true, desc = "Toggle Terminal" }) --
