return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"stevearc/conform.nvim",
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
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
		local uv = vim.uv or vim.loop
		local function clangd_include_paths()
			local include_paths = {}
			local seen = {}
			local function add_include(path)
				if not path or path == "" then
					return
				end
				if not uv.fs_stat(path) or seen[path] then
					return
				end
				seen[path] = true
				table.insert(include_paths, path)
			end

			add_include("/opt/homebrew/include")
			add_include("/usr/local/include")

			if vim.fn.executable("brew") == 1 then
				local brew_prefix = vim.fn.systemlist({ "brew", "--prefix" })
				if vim.v.shell_error == 0 and brew_prefix[1] then
					add_include(brew_prefix[1] .. "/include")
				end
				local raylib_prefix = vim.fn.systemlist({ "brew", "--prefix", "raylib" })
				if vim.v.shell_error == 0 and raylib_prefix[1] then
					add_include(raylib_prefix[1] .. "/include")
				end
			end

			return include_paths
		end
		local clangd_include_flags = {}
		for _, path in ipairs(clangd_include_paths()) do
			table.insert(clangd_include_flags, "-I" .. path)
		end
		local clangd_cmd = { "clangd" }
		for _, flag in ipairs(clangd_include_flags) do
			table.insert(clangd_cmd, "--extra-arg=" .. flag)
		end

		require("fidget").setup({})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"clangd",
				"lua_ls",
				"rust_analyzer",
				"gopls",
				"vtsls",
				"tailwindcss",
				"sourcekit",
			},
			handlers = {
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,
				["clangd"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.clangd.setup({
						capabilities = capabilities,
						cmd = clangd_cmd,
						init_options = {
							fallbackFlags = clangd_include_flags,
						},
					})
				end,

				zls = function()
					local lspconfig = require("lspconfig")
					lspconfig.zls.setup({
						root_dir = lspconfig.util.root_pattern(".git", "build.zig", "zls.json"),
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
				end,
				["lua_ls"] = function()
					local lspconfig = require("lspconfig")

					lspconfig.lua_ls.setup({
						capabilities = capabilities,
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
				end,
				["tailwindcss"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.tailwindcss.setup({
						capabilities = capabilities,
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
				end,
			},
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
