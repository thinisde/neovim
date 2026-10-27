local M = {}
local uv = vim.uv or vim.loop
local requests = {}
local saved_options = {}

local function save_options(buf)
	if saved_options[buf] then
		return
	end
	saved_options[buf] = {}
	for _, name in ipairs({
		"buftype",
		"readonly",
		"modifiable",
		"swapfile",
		"undofile",
		"undolevels",
		"modeline",
		"filetype",
	}) do
		saved_options[buf][name] = vim.bo[buf][name]
	end
end

local object_magic = {
	["\127ELF"] = true,
	["\254\237\250\206"] = true,
	["\206\250\237\254"] = true,
	["\254\237\250\207"] = true,
	["\207\250\237\254"] = true,
	["\202\254\186\190"] = true,
	["\190\186\254\202"] = true,
	["\202\254\186\191"] = true,
	["\191\186\254\202"] = true,
}

local function read_sample(path)
	local stat = uv.fs_stat(path)
	if not stat or stat.type ~= "file" then
		return
	end
	local fd = uv.fs_open(path, "r", 438)
	if not fd then
		return
	end
	local sample = uv.fs_read(fd, math.min(stat.size, 8192), 0) or ""
	uv.fs_close(fd)
	return sample
end

local function detect(path)
	local sample = read_sample(path)
	if not sample then
		return
	end
	if
		object_magic[sample:sub(1, 4)]
		or (sample:sub(1, 2) == "MZ" and sample:find("\0", 1, true))
		or sample:sub(1, 8) == "!<arch>\n"
		or sample:sub(1, 8) == "!<thin>\n"
	then
		return "assembly"
	end
	if sample:find("\0", 1, true) or path:lower():match("%.bin$") or path:lower():match("%.rom$") then
		return "hex"
	end
end

local function command_for(mode, path)
	if mode == "hex" then
		if vim.fn.executable("xxd") == 1 then
			return { "xxd", "-c", "2", "-g", "16", path }
		end
		return nil, "HexView requires xxd on PATH"
	end
	local include_headers = mode == "assembly_headers"
	local magic = include_headers and (read_sample(path) or ""):sub(1, 4) or ""
	local macho = object_magic[magic] and magic ~= "\127ELF"
	for _, executable in ipairs({ "llvm-objdump", "objdump" }) do
		if vim.fn.executable(executable) == 1 then
			local command = { executable, "-d", "--demangle" }
			if include_headers then
				if macho then
					vim.list_extend(command, { "--macho", "--private-headers", "--section-headers" })
				else
					table.insert(command, "--all-headers")
				end
			end
			table.insert(command, path)
			return command
		end
	end
	if vim.fn.executable("otool") == 1 then
		if include_headers then
			return { "otool", "-h", "-l", "-t", "-v", "-V", path }
		end
		return { "otool", "-tvV", path }
	end
	return nil, "AssemblyView requires llvm-objdump, objdump, or otool on PATH"
end

local function render(buf, mode, output)
	local options = vim.bo[buf]
	options.modifiable = true
	options.readonly = false
	options.buftype = "nowrite"
	options.swapfile = false
	options.undofile = false
	options.undolevels = -1
	options.binary = false
	options.modeline = false
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n", { trimempty = true }))
	options.modified = false
	options.readonly = true
	options.modifiable = false
	options.filetype = mode == "hex" and "xxd" or "asm"
	vim.b[buf].binary_view = mode
end

function M.view(buf, mode, automatic)
	local path = vim.b[buf].binary_source or vim.api.nvim_buf_get_name(buf)
	if path == "" or vim.fn.filereadable(path) ~= 1 then
		vim.notify("Open a readable file first", vim.log.levels.ERROR)
		return
	end
	if not automatic and vim.bo[buf].modified then
		vim.notify("Save changes before opening a file view", vim.log.levels.WARN)
		return
	end
	local command, error_message = command_for(mode, path)
	if not command then
		vim.notify(error_message, vim.log.levels.ERROR)
		if automatic and mode == "assembly" then
			M.view(buf, "hex", true)
		elseif automatic then
			render(buf, mode, error_message)
		end
		return
	end

	local request = {}
	requests[buf] = request
	save_options(buf)
	vim.b[buf].binary_source = path
	if automatic then
		render(buf, mode, "Loading " .. mode .. " view...")
	end
	local ok, spawn_error = pcall(
		vim.system,
		command,
		{ text = true, timeout = 15000 },
		vim.schedule_wrap(function(result)
			if requests[buf] ~= request or not vim.api.nvim_buf_is_loaded(buf) then
				return
			end
			requests[buf] = nil
			if result.code == 0 then
				render(buf, mode, result.stdout or "")
				return
			end
			local message = (result.stderr or ""):gsub("%s+$", "")
			if message == "" then
				message = command[1] .. " exited with status " .. result.code
			end
			if automatic and mode == "assembly" then
				vim.notify("Cannot disassemble this file; opening hex view", vim.log.levels.WARN)
				M.view(buf, "hex", true)
			else
				vim.notify(message, vim.log.levels.ERROR)
				if automatic then
					render(buf, mode, message)
				end
			end
		end)
	)
	if not ok then
		requests[buf] = nil
		vim.notify(tostring(spawn_error), vim.log.levels.ERROR)
		if automatic then
			render(buf, mode, tostring(spawn_error))
		end
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("BinaryViews", { clear = true })
	vim.api.nvim_create_autocmd("BufReadPre", {
		group = group,
		callback = function(args)
			requests[args.buf] = nil
			if saved_options[args.buf] then
				vim.bo[args.buf].binary = false
				for name, value in pairs(saved_options[args.buf]) do
					vim.bo[args.buf][name] = value
				end
				saved_options[args.buf] = nil
				vim.b[args.buf].binary_view = nil
				vim.b[args.buf].binary_source = nil
			end
			local path = vim.api.nvim_buf_get_name(args.buf)
			local mode = detect(path)
			vim.b[args.buf].binary_auto_view = mode
			if mode then
				save_options(args.buf)
				vim.b[args.buf].binary_source = path
				vim.bo[args.buf].binary = true
				vim.bo[args.buf].readonly = true
				vim.bo[args.buf].modeline = false
				vim.bo[args.buf].swapfile = false
				vim.bo[args.buf].undofile = false
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		callback = function(args)
			local mode = vim.b[args.buf].binary_auto_view
			if mode then
				M.view(args.buf, mode, true)
			end
		end,
	})
	vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
		group = group,
		callback = function(args)
			requests[args.buf] = nil
			if args.event == "BufWipeout" then
				saved_options[args.buf] = nil
			end
		end,
	})
	vim.api.nvim_create_user_command("HexView", function()
		M.view(vim.api.nvim_get_current_buf(), "hex", false)
	end, { desc = "View the current file's bytes as hex" })
	vim.api.nvim_create_user_command("AssemblyView", function()
		M.view(vim.api.nvim_get_current_buf(), "assembly", false)
	end, { desc = "Disassemble the current binary file" })
	vim.api.nvim_create_user_command("AssemblyViewIncludeHeader", function()
		M.view(vim.api.nvim_get_current_buf(), "assembly_headers", false)
	end, { desc = "Show binary headers and disassembly for the current file" })
end

return M
