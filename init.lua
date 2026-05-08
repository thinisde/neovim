require("core.options")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.keymaps")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- Disable statusline in Neovim (using vim-tpipeline to show in tmux instead)
vim.o.showmode = false
vim.o.cmdheight = 0
vim.o.laststatus = 0

vim.g.python3_host_prog = "/opt/homebrew/opt/python@3.14/libexec/bin/python"

vim.env.PATH = vim.env.PATH .. ":/opt/homebrew/bin"

vim.lsp.set_log_level("ERROR")

require("lazy").setup("plugins")

require("core.setup")
