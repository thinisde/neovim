-- Clipboard bridge for SSH/tmux sessions.
--
-- Over SSH the only clipboard we can reach is the one in the terminal that
-- runs the SSH client, via OSC 52. OSC 52 *writes* are instant; *reads* are
-- not — tmux/terminals do not answer the query and Neovim then blocks for up
-- to 10 seconds. So the `+`/`*` registers are backed by a provider that:
--   * writes yanks to the client clipboard with OSC 52,
--   * caches the last copy in memory so `"+p` is instant,
--   * never queries the terminal.
-- Text copied on the client (browser, editor, ...) is pasted with the
-- terminal's own paste shortcut (Ctrl+Shift+V / Cmd+V).
local M = {}

-- Most terminals cap OSC 52 payloads around 100 KB.
local MAX_OSC52_BYTES = 100 * 1024

local cached = { {}, "v" }

local function has_gui_clipboard()
	return vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil
end

local function copy(lines, regtype)
	cached = { lines, regtype }
	local payload = table.concat(lines, "\n")
	if #payload > MAX_OSC52_BYTES then
		vim.notify("Selection too large for the OSC 52 clipboard", vim.log.levels.WARN)
		return
	end
	-- Same escape the built-in osc52 provider emits; chan_send handles EAGAIN.
	vim.api.nvim_chan_send(2, "\027]52;c;" .. vim.base64.encode(payload) .. "\027\\")
end

local function paste()
	return cached
end

local function sync_yank(regname, regtype)
	local reg = regname ~= "" and regname or '"'
	local text = vim.fn.getreg(reg, 1, true)
	if type(text) ~= "table" or #text == 0 then
		return
	end
	-- Blockwise yanks need a width `setreg` cannot infer here; send them as
	-- normal characterwise text.
	if regtype ~= "v" and regtype ~= "V" then
		regtype = "v"
	end
	pcall(vim.fn.setreg, "+", text, regtype)
end

function M.setup()
	if has_gui_clipboard() then
		-- Real clipboard available (local X/Wayland, or `ssh -X` forwarding).
		vim.o.clipboard = "unnamedplus"
		return
	end

	vim.g.clipboard = {
		name = "ssh-osc52",
		copy = { ["+"] = copy, ["*"] = copy },
		paste = { ["+"] = paste, ["*"] = paste },
	}
	vim.o.clipboard = "" -- never read `+` implicitly on `p`/`P`
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("user-osc52-yank", { clear = true }),
		callback = function()
			-- An explicit `"+y` already wrote to the client clipboard.
			if vim.v.event.regname ~= "+" then
				sync_yank(vim.v.event.regname, vim.v.event.regtype)
			end
		end,
		desc = "Mirror yanks to the SSH client clipboard via OSC 52",
	})
end

return M
