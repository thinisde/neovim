-- Standalone plugins with less than 10 lines of config go here
return {
	{
		-- Detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",
	},
	{
		-- Hints keybinds
		"folke/which-key.nvim",
		dependencies = { "echasnovski/mini.icons" },
	},
	{
		-- Autoclose parentheses, brackets, quotes, etc.
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		opts = {},
	},
	{
		-- High-performance color highlighter (NvChad fork is maintained;
		-- norcalli/ upstream uses deprecated vim.tbl_flatten)
		"NvChad/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup()
		end,
	},
	{
		-- WakaTime time tracker
		"wakatime/vim-wakatime",
		lazy = false,
	},
	{
		"vimpostor/vim-tpipeline",
		event = "VeryLazy",
		config = function()
			vim.g.tpipeline_focuslost = 1
			vim.o.laststatus = 0
			vim.go.laststatus = 0
		end,
	},
}
