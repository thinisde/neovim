local augroup = vim.api.nvim_create_augroup("AutoLcdGitRoot", { clear = true })

local state = { last_root = nil }

local function git_root(startpath)
	if not startpath or startpath == "" then
		return nil
	end

	-- Find nearest .git (can be a directory OR a file, so don't force type=directory)
	local found = vim.fs.find(".git", { path = startpath, upward = true })
	if not found or not found[1] then
		return nil
	end

	-- repo_dir = folder containing .git
	local repo_dir = vim.fs.dirname(found[1])
	if not repo_dir or repo_dir == "" then
		return nil
	end

	return repo_dir
end

local function lcd(dir)
	if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
		pcall(vim.cmd, { cmd = "lcd", args = { dir } })
	end
end

local function is_special(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return true
	end

	local bt = vim.bo[buf].buftype
	local ft = vim.bo[buf].filetype
	local name = vim.api.nvim_buf_get_name(buf) or ""

	-- Any "non-file" buftype is special (except acwrite which some plugins use for real editing)
	if bt ~= "" and bt ~= "acwrite" then
		return true
	end

	-- Common special filetypes (plugin UIs / transient views)
	local special_ft = {
		-- fuzzy finders / pickers
		TelescopePrompt = true,
		TelescopeResults = true,

		-- git
		fugitive = true,
		git = true,
		diff = true,

		-- terminals
		toggleterm = true,

		-- tree/file explorers
		["neo-tree"] = true,
		NvimTree = true,

		-- misc UIs
		help = true,
		qf = true,
		man = true,
		notify = true,
		dressinginput = true,
		dressingselect = true,
		lazy = true,
		mason = true,
		["checkhealth"] = true,
	}
	if special_ft[ft] then
		return true
	end

	-- Name-based detection (more precise than ft alone)
	-- fugitive buffers often look like: fugitive://..., git://..., or .git/...
	if name:match("^fugitive://") or name:match("^git://") or name:match("/%.git/") then
		return true
	end

	-- Some terminal buffers have empty ft but special names
	if name:match("^term://") then
		return true
	end

	return false
end

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
	group = augroup,
	callback = function(args)
		local buf = args.buf

		if is_special(buf) then
			if state.last_root then
				lcd(state.last_root)
			else
				local cwd = vim.uv.cwd()
				lcd(git_root(cwd) or cwd)
			end
			return
		end

		if vim.bo[buf].buftype ~= "" then
			return
		end

		local name = vim.api.nvim_buf_get_name(buf)
		if name == "" then
			return
		end

		local dir = vim.fs.dirname(name)
		if not dir or vim.fn.isdirectory(dir) ~= 1 then
			return
		end

		state.last_root = git_root(dir) or state.last_root
		lcd(dir)
	end,
})
