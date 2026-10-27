return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"hrsh7th/nvim-cmp",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"j-hui/fidget.nvim",
	},

	config = function()
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		local has_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
		if not has_cmp_lsp then
			pcall(vim.cmd, "packadd cmp-nvim-lsp")
			has_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
		end
		if has_cmp_lsp then
			capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
		end

		-- Default capabilities for all servers (new vim.lsp.config API).
		-- This merges with the defaults shipped in nvim-lspconfig/lsp/*.lua.
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		local clangd_cmd = {
			"clangd",
			"--background-index",
			"--clang-tidy",
			"--completion-style=detailed",
			"--header-insertion=never",
		}

		local query_drivers = {
			-- Homebrew ARM toolchains on Apple Silicon and Intel Macs.
			"/opt/homebrew/bin/arm-none-eabi-*",
			"/usr/local/bin/arm-none-eabi-*",
			-- Official Arm GNU Toolchain installed through gcc-arm-embedded.
			"/Applications/ArmGNUToolchain/*/arm-none-eabi/bin/arm-none-eabi-*",
		}

		-- AVR support
		local avr_gcc = vim.fn.exepath("avr-gcc")
		local avr_gxx = vim.fn.exepath("avr-g++")

		if avr_gcc ~= "" then
			table.insert(query_drivers, avr_gcc)
		end

		if avr_gxx ~= "" then
			table.insert(query_drivers, avr_gxx)
		end

		table.insert(clangd_cmd, "--query-driver=" .. table.concat(query_drivers, ","))

		require("fidget").setup({
			notification = {
				window = {
					-- Silence checkhealth warning about implicit xcodebuild.nvim integration.
					avoid = { "TestExplorer" },
				},
			},
		})
		require("mason").setup()

		-- clangd owns C/C++/Objective-C, including embedded ARM and AVR projects.
		vim.lsp.config("clangd", {
			cmd = clangd_cmd,
			capabilities = vim.tbl_deep_extend("force", capabilities, {
				general = {
					positionEncodings = { "utf-8", "utf-16" },
				},
			}),
		})

		vim.lsp.config("zls", {
			root_markers = { ".git", "build.zig", "zls.json" },
			settings = {
				zls = {
					enable_inlay_hints = true,
					enable_snippets = true,
					warn_style = true,
				},
			},
		})
		vim.g.zig_fmt_parse_errors = 0
		vim.g.zig_fmt_autosave = 0

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					format = {
						enable = true,
						-- Put format options here
						-- NOTE: the value should be STRING!!
						defaultConfig = {
							indent_style = "space",
							indent_size = "4",
						},
					},
				},
			},
		})

		vim.lsp.config("tailwindcss", {
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"svelte",
				"heex",
			},
		})

		vim.lsp.config("sourcekit", {
			cmd = { "xcrun", "sourcekit-lsp" },
			filetypes = { "swift" },
		})

		require("mason-lspconfig").setup({
			ensure_installed = {
				"clangd",
				"lua_ls",
				"rust_analyzer",
				"gopls",
				"vtsls",
				"tailwindcss",
			},
			-- Enable the selected servers explicitly below.
			automatic_enable = false,
		})

		-- Mason supplies clangd and the other servers; Xcode supplies SourceKit.
		vim.lsp.enable({
			"clangd",
			"sourcekit",
			"lua_ls",
			"rust_analyzer",
			"gopls",
			"vtsls",
			"tailwindcss",
			"zls",
		})

		local ok_cmp, cmp = pcall(require, "cmp")
		if ok_cmp then
			local cmp_select = { behavior = cmp.SelectBehavior.Select }
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
					["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})
		end

		vim.diagnostic.config({
			-- update_in_insert = true,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
	end,
}
