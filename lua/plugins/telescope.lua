local function patch_remote_sshfs_connect(extension)
	if type(extension) ~= "table" or type(extension.connect) ~= "function" then
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local state = require("telescope.actions.state")
	local sorters = require("telescope.sorters")
	local connections = require("remote-sshfs.connections")

	extension.connect = function(opts)
		local hosts = connections.list_hosts() or {}
		local host_names = vim.tbl_keys(hosts)

		if vim.tbl_isempty(host_names) then
			vim.notify(
				"remote-sshfs: no hosts found. Add hosts to ~/.ssh/config or configure connections.ssh_configs.",
				vim.log.levels.WARN
			)
			return
		end

		pickers
			.new(opts, {
				prompt_title = "Connect to remote host",
				finder = finders.new_table({
					results = host_names,
				}),
				sorter = sorters.get_fzy_sorter(),
				attach_mappings = function(prompt_bufnr, _)
					actions.select_default:replace(function()
						local selection = state.get_selected_entry()
						local host_name = selection and (selection[1] or selection.value)
						local host = host_name and hosts[host_name] or nil

						if not host then
							vim.notify("remote-sshfs: no host selected.", vim.log.levels.WARN)
							return
						end

						actions.close(prompt_bufnr)
						connections.connect(host)

						vim.schedule(function()
							vim.cmd("stopinsert")
						end)
					end)

					return true
				end,
			})
			:find()
	end
end

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
		})
	end,
}
