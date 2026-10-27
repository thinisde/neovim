-- ftplugin for MMIXAL (`*.mms`) sources.
if vim.b.did_ftplugin == 1 then
	return
end
vim.b.did_ftplugin = 1

-- MMIX comments start with `%` (Knuth style) or `//`.
vim.opt_local.commentstring = "% %s"
vim.opt_local.comments = ":%,://"
-- MMIXAL is free-format; spaces keep label/opcode columns readable.
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 8
vim.opt_local.tabstop = 8
-- mmixal truncates input lines past its buffer (`-b`); 70 cols is safe.
vim.opt_local.textwidth = 70

vim.cmd("compiler mmixal")

-- Nearest project root (a `Makefile` or `.git` found upward).
local function project_root()
	local name = vim.api.nvim_buf_get_name(0)
	local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
	local found = vim.fs.find({ "Makefile", ".git" }, { upward = true, path = dir })
	if #found == 0 then
		return nil
	end
	return vim.fs.dirname(found[1])
end

local function qf_errors()
	return vim.tbl_filter(function(e)
		return e.valid == 1
	end, vim.fn.getqflist())
end

local function assemble_silent()
	vim.cmd("silent update")
	vim.cmd("silent make!")
	return qf_errors()
end

vim.api.nvim_buf_create_user_command(0, "MmixAssemble", function()
	vim.cmd("update")
	vim.cmd("make")
end, { desc = "Assemble current MMIX file with mmixal (:make)" })

vim.api.nvim_buf_create_user_command(0, "MmixRun", function()
	local errs = assemble_silent()
	if #errs > 0 then
		vim.cmd("copen")
		vim.notify("mmixal: " .. #errs .. " error(s), run aborted", vim.log.levels.ERROR)
		return
	end
	vim.cmd("!mmix -q " .. vim.fn.shellescape(vim.fn.expand("%:r")))
end, { desc = "Assemble and run current MMIX file with mmix" })

vim.api.nvim_buf_create_user_command(0, "MmixListing", function()
	local errs = assemble_silent()
	if #errs > 0 then
		vim.cmd("copen")
		return
	end
	local lst = vim.fn.expand("%:r") .. ".lst"
	if vim.fn.filereadable(lst) == 1 then
		vim.cmd("vsplit " .. vim.fn.fnameescape(lst))
	else
		vim.notify("No listing produced: " .. lst, vim.log.levels.WARN)
	end
end, { desc = "Assemble current MMIX file and open its .lst listing" })

vim.api.nvim_buf_create_user_command(0, "MmixProjectBuild", function()
	local root = project_root()
	if not root then
		vim.notify("No Makefile/.git found upward", vim.log.levels.WARN)
		return
	end
	vim.cmd("!make -C " .. vim.fn.shellescape(root))
end, { desc = "Run project make (nearest Makefile upward)" })

vim.api.nvim_buf_create_user_command(0, "MmixProjectCheck", function()
	local root = project_root()
	if not root then
		vim.notify("No Makefile/.git found upward", vim.log.levels.WARN)
		return
	end
	vim.cmd("!make -C " .. vim.fn.shellescape(root) .. " check")
end, { desc = "Rebuild and run all project MMIX examples" })

local map_opts = { buffer = true, silent = true }
vim.keymap.set("n", "<leader>ma", "<cmd>MmixAssemble<CR>", map_opts)
vim.keymap.set("n", "<leader>mr", "<cmd>MmixRun<CR>", map_opts)
vim.keymap.set("n", "<leader>ml", "<cmd>MmixListing<CR>", map_opts)
vim.keymap.set("n", "<leader>mm", "<cmd>MmixProjectBuild<CR>", map_opts)
vim.keymap.set("n", "<leader>mc", "<cmd>MmixProjectCheck<CR>", map_opts)
