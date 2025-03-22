local config = require("pathtool.config")
local core = require("pathtool.core")

local M = {}

M.show_path_preview = function()
	local paths_data = core.get_all_paths()
	
	if not next(paths_data) then
		core.notify("No file open", "warn")
		return
	end
	
	local buf = vim.api.nvim_create_buf(false, true)

	local width = math.min(vim.o.columns - 4, 80)
	local height = 12
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " pathtool Path Preview ",
		title_pos = "center",
	}

	local lines = {}
	local max_label_len = 0

	for label, _ in pairs(paths_data) do
		max_label_len = math.max(max_label_len, #label)
	end

	for label, path in pairs(paths_data) do
		local padded_label = label .. string.rep(" ", max_label_len - #label)
		table.insert(lines, string.format("%s : %s", padded_label, path))
	end

	table.insert(lines, "")
	table.insert(lines, "Press key to copy: [a]bsolute [r]elative [p]roject [f]ilename [d]irectory")
	table.insert(lines, "                   [n]ame-no-ext [c]onverted [u]rl [q/Esc]uit")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	vim.api.nvim_win_set_option(win, "winhl", "Normal:pathtoolNormal,FloatBorder:pathtoolBorder")
	vim.cmd([[
		highlight pathtoolNormal guibg=#1a1b26 guifg=#c0caf5
		highlight pathtoolBorder guibg=#1a1b26 guifg=#7aa2f7
	]])

	local path_mapping = {
		a = paths_data["Absolute Path"],
		r = paths_data["Relative Path"],
		p = paths_data["Project Path"],
		f = paths_data["Filename"],
		n = paths_data["Filename (no ext)"],
		d = paths_data["Directory"],
		c = paths_data["Converted Style"],
		u = paths_data["File URL"],
	}

	for key, path in pairs(path_mapping) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
			callback = function()
				if path then
					core.copy_to_clipboard(path)
					vim.api.nvim_win_close(win, true)
				end
			end,
			noremap = true,
		})
	end

	for _, key in ipairs({ "q", "<Esc>" }) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
			callback = function()
				vim.api.nvim_win_close(win, true)
			end,
			noremap = true,
		})
	end

	vim.api.nvim_create_autocmd({ "BufLeave" }, {
		buffer = buf,
		once = true,
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
	})
end

return M
