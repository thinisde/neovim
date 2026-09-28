return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"stevearc/conform.nvim",
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
		local ok_conform, conform = pcall(require, "conform")
		if ok_conform then
			conform.setup({
				formatters_by_ft = {},
			})
		end

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
			-- Raspberry Pi Pico / ARM bare-metal
			"/opt/homebrew/bin/arm-none-eabi-*",
			"/usr/local/bin/arm-none-eabi-*",

			-- Official Arm GNU Toolchain installed through gcc-arm-embedded
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

		-- Per-server overrides via the new vim.lsp.config API.
		-- These merge with nvim-lspconfig defaults; mason-lspconfig then
		-- auto-enables the installed servers with vim.lsp.enable().
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

		require("mason-lspconfig").setup({
			ensure_installed = {
				"clangd",
				"lua_ls",
				"rust_analyzer",
				"gopls",
				"vtsls",
				"tailwindcss",
			},
			-- New v2 API: no `handlers` table. Servers installed via Mason
			-- are automatically enabled with vim.lsp.enable().
			automatic_enable = true,
		})

		-- sourcekit-lsp also claims c/cpp (and matches compile_commands.json),
		-- which makes it attach alongside clangd on bare-metal projects and
		-- report bogus host-SDK diagnostics (e.g. 'cassert' not found).
		-- Restrict it to Apple languages; clangd owns c/cpp.
		vim.lsp.config("sourcekit", {
			filetypes = { "swift", "objc", "objcpp" },
		})

		-- Explicitly enable servers (covers Mason-installed + system ones
		-- like sourcekit from Xcode). `vim.lsp.enable` is idempotent.
		vim.lsp.enable({
			"clangd",
			"lua_ls",
			"rust_analyzer",
			"gopls",
			"vtsls",
			"tailwindcss",
			"zls",
			"sourcekit",
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
