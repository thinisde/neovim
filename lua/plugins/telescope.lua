return {
	"nvim-telescope/telescope.nvim",

	dependencies = {
		"nvim-lua/plenary.nvim",
	},

	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				preview = {
					-- telescope 0.1.5 expects old nvim-treesitter parser APIs.
					-- Disable TS preview highlighting to avoid callback errors.
					treesitter = false,
				},
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
					},
				},
			},
			pickers = {
				find_files = {
					-- Use ripgrep so find_files respects .gitignore and related ignore files.
					find_command = { "rg", "--files" },
				},
			},
		})
	end,
}
