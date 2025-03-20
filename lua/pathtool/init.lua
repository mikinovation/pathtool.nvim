local utils = require("pathtool.utils")

local M = {}

M.config = {
	keymaps = {
		copy_absolute_path = "<leader>pa",
		copy_relative_path = "<leader>pr",
		copy_filename = "<leader>pf",
		copy_dirname = "<leader>pd",
		copy_project_path = "<leader>pp",
		convert_path_style = "<leader>pc",
		open_preview = "<leader>po",
	},
	use_system_clipboard = true,
	show_notifications = true,
	notification_timeout = 3000,
	path_display_length = 60,
	detect_project_root = true,
	project_markers = {
		".git",
		".svn",
		"package.json",
		"Cargo.toml",
		"go.mod",
		"Makefile",
		".project",
		"CMakeLists.txt",
		"pyproject.toml",
	},
}

local function notify(msg, level, opts)
	level = level or "info"
	opts = opts or {}

	if M.config.show_notifications then
		if vim.notify then
			vim.notify(msg, vim.log.levels[string.upper(level)], {
				title = "pathtool",
				timeout = opts.timeout or M.config.notification_timeout,
			})
		else
			local levels = { INFO = "", WARN = "WARNING: ", ERROR = "ERROR: " }
			print(levels[string.upper(level)] .. msg)
		end
	end
end

M.get_absolute_path = function()
	local filename = vim.fn.expand("%:p")
	if filename == "" then
		notify("No file open", "warn")
		return nil
	end

	filename = utils.normalize_path(filename)
	return filename
end

M.get_relative_path = function()
	local filename = vim.fn.expand("%:.")
	if filename == "" then
		notify("No file open", "warn")
		return nil
	end

	filename = utils.normalize_path(filename)
	return filename
end

M.find_project_root = function()
	if not M.config.detect_project_root then
		return vim.fn.getcwd()
	end

	local current_dir = vim.fn.expand("%:p:h")
	if current_dir == "" then
		current_dir = vim.fn.getcwd()
	end

	for _, marker in ipairs(M.config.project_markers) do
		local result = vim.fn.finddir(marker, current_dir .. ";")
		if result ~= "" then
			-- マーカーがディレクトリの場合
			return vim.fn.fnamemodify(result, ":p:h:h")
		end

		result = vim.fn.findfile(marker, current_dir .. ";")
		if result ~= "" then
			-- マーカーがファイルの場合
			return vim.fn.fnamemodify(result, ":p:h")
		end
	end

	return current_dir
end

M.get_project_relative_path = function()
	local abs_path = M.get_absolute_path()
	if not abs_path then
		return nil
	end

	local root = M.find_project_root()
	if not root then
		notify("Project root not found", "warn")
		return abs_path
	end

	local rel_path = utils.path_relative_to(abs_path, root)
	return rel_path
end

M.get_filename = function()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		notify("No file open", "warn")
		return nil
	end
	return filename
end

M.get_filename_without_ext = function()
	local filename = vim.fn.expand("%:t:r")
	if filename == "" then
		notify("No file open", "warn")
		return nil
	end
	return filename
end

M.get_dirname = function()
	local dirname = vim.fn.expand("%:p:h")
	if dirname == "" then
		notify("No file open", "warn")
		return nil
	end

	dirname = utils.normalize_path(dirname)
	return dirname
end

M.convert_path_style = function()
	local path = M.get_absolute_path()
	if not path then
		return nil
	end

	return utils.convert_path_style(path)
end

M.encode_path_as_url = function()
	local path = M.get_absolute_path()
	if not path then
		return nil
	end

	local file_url = utils.path_to_file_url(path)
	return file_url
end

M.copy_to_clipboard = function(text)
	if not text then
		return false
	end

	if M.config.use_system_clipboard then
		vim.fn.setreg("+", text)
	end
	vim.fn.setreg('"', text)

	local display_text = text
	if #text > M.config.path_display_length then
		display_text = "..." .. string.sub(text, -M.config.path_display_length)
	end

	notify("Copied: " .. display_text, "info")
	return true
end

M.setup_commands = function()
	vim.api.nvim_create_user_command("PathCopyAbsolute", function()
		M.copy_to_clipboard(M.get_absolute_path())
	end, { desc = "Copy absolute path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyRelative", function()
		M.copy_to_clipboard(M.get_relative_path())
	end, { desc = "Copy relative path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyProject", function()
		M.copy_to_clipboard(M.get_project_relative_path())
	end, { desc = "Copy project relative path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyFilename", function()
		M.copy_to_clipboard(M.get_filename())
	end, { desc = "Copy filename to clipboard" })

	vim.api.nvim_create_user_command("PathCopyFilenameNoExt", function()
		M.copy_to_clipboard(M.get_filename_without_ext())
	end, { desc = "Copy filename without extension to clipboard" })

	vim.api.nvim_create_user_command("PathCopyDirname", function()
		M.copy_to_clipboard(M.get_dirname())
	end, { desc = "Copy directory path to clipboard" })

	vim.api.nvim_create_user_command("PathConvertStyle", function()
		M.copy_to_clipboard(M.convert_path_style())
	end, { desc = "Convert and copy path between Unix/Windows style" })

	vim.api.nvim_create_user_command("PathToUrl", function()
		M.copy_to_clipboard(M.encode_path_as_url())
	end, { desc = "Convert path to file URL and copy" })

	vim.api.nvim_create_user_command("PathPreview", function()
		M.show_path_preview()
	end, { desc = "Show path preview window" })
end

M.setup_keymaps = function()
	local keymaps = M.config.keymaps

	vim.keymap.set("n", keymaps.copy_absolute_path, function()
		M.copy_to_clipboard(M.get_absolute_path())
	end, { desc = "Copy absolute path" })

	vim.keymap.set("n", keymaps.copy_relative_path, function()
		M.copy_to_clipboard(M.get_relative_path())
	end, { desc = "Copy relative path" })

	vim.keymap.set("n", keymaps.copy_project_path, function()
		M.copy_to_clipboard(M.get_project_relative_path())
	end, { desc = "Copy project relative path" })

	vim.keymap.set("n", keymaps.copy_filename, function()
		M.copy_to_clipboard(M.get_filename())
	end, { desc = "Copy filename" })

	vim.keymap.set("n", keymaps.copy_dirname, function()
		M.copy_to_clipboard(M.get_dirname())
	end, { desc = "Copy directory path" })

	vim.keymap.set("n", keymaps.convert_path_style, function()
		M.copy_to_clipboard(M.convert_path_style())
	end, { desc = "Convert path style" })

	vim.keymap.set("n", keymaps.open_preview, function()
		M.show_path_preview()
	end, { desc = "Open path preview" })
end

M.show_path_preview = function()
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

	local paths = {
		["Absolute Path"] = M.get_absolute_path() or "N/A",
		["Relative Path"] = M.get_relative_path() or "N/A",
		["Project Path"] = M.get_project_relative_path() or "N/A",
		["Filename"] = M.get_filename() or "N/A",
		["Filename (no ext)"] = M.get_filename_without_ext() or "N/A",
		["Directory"] = M.get_dirname() or "N/A",
		["Converted Style"] = M.convert_path_style() or "N/A",
		["File URL"] = M.encode_path_as_url() or "N/A",
	}

	local lines = {}
	local max_label_len = 0

	for label, _ in pairs(paths) do
		max_label_len = math.max(max_label_len, #label)
	end

	for label, path in pairs(paths) do
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

	local mappings = {
		a = "get_absolute_path",
		r = "get_relative_path",
		p = "get_project_relative_path",
		f = "get_filename",
		n = "get_filename_without_ext",
		d = "get_dirname",
		c = "convert_path_style",
		u = "encode_path_as_url",
	}

	for key, func_name in pairs(mappings) do
		vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
			callback = function()
				local result = M[func_name]()
				if result then
					M.copy_to_clipboard(result)
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

M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	M.setup_commands()
	M.setup_keymaps()

	notify("pathtool.nvim has been loaded", "info")
end

return M
