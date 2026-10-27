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

-- Homebrew and user-installed tools, including GUI-launched Neovim sessions.
vim.env.PATH = table.concat({
	"/opt/homebrew/bin",
	"/opt/homebrew/sbin",
	"/usr/local/bin",
	"/usr/local/sbin",
	vim.env.HOME .. "/.local/bin",
	vim.env.HOME .. "/.cargo/bin",
	vim.env.HOME .. "/go/bin",
	vim.env.PATH or "",
}, ":")

-- Resolve Python after Homebrew has been added to PATH.
local python3 = vim.fn.exepath("python3")
if python3 ~= "" then
	vim.g.python3_host_prog = python3
else
	vim.g.loaded_python3_provider = 0
end

vim.lsp.log.set_level("ERROR")
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Open compiled binaries as assembly and other binary data as hex.
require("core.binary").setup()

require("lazy").setup("plugins")

require("core.setup")
