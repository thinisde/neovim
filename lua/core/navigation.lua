-- Seamless navigation: Alt+h/j/k/l moves between Neovim splits and, when
-- there is no split in that direction, hands off to the tmux pane.
local M = {}

local function move(win_cmd, tmux_flag)
	local before = vim.api.nvim_get_current_win()
	vim.cmd("wincmd " .. win_cmd)
	if vim.api.nvim_get_current_win() == before and vim.env.TMUX then
		vim.fn.system({ "tmux", "select-pane", tmux_flag })
	end
end

function M.setup()
	local maps = {
		h = { "h", "-L" },
		j = { "j", "-D" },
		k = { "k", "-U" },
		l = { "l", "-R" },
	}
	for key, spec in pairs(maps) do
		vim.keymap.set({ "n", "t" }, "<M-" .. key .. ">", function()
			move(spec[1], spec[2])
		end, { silent = true, desc = "Go to " .. key .. " window/pane" })
	end
end

return M
