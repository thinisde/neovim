vim.treesitter.start(0, "eex")

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. "\n call v:lua.vim.treesitter.stop()"
