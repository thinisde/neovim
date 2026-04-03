return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				swift = { "swiftformat" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
				go = { "gofmt" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				elixir = { "mix" },
				java = { "google-java-format" },
			},
			formatters = {
				["clang-format"] = {
					prepend_args = { "-style=file", "-fallback-style=LLVM" },
				},
				["google-java-format"] = {
					prepend_args = { "--aosp" },
				},
				swiftformat = {
					command = "swiftformat",
					-- SwiftFormat expects --stdinpath only when reading from stdin
					args = { "--quiet", "--stdinpath", "$FILENAME" },
					stdin = true,
				},
			},
			format_on_save = function(bufnr)
				if vim.bo[bufnr].filetype == "oil" then
					return
				end
				return { timeout_ms = 500, lsp_fallback = true }
			end,
			log_level = vim.log.levels.ERROR,
		})
	end,
}
