local utils = require("pathtool.utils")
local config = require("pathtool.config")

local M = {}

--- Displays a notification
-- @param msg string Message to display
-- @param level string (optional) Log level ('info', 'warn', 'error') (default: 'info')
-- @param opts table (optional) Additional options like timeout
function M.notify(msg, level, opts)
	level = level or "info"
	opts = opts or {}

	if config.get("show_notifications") then
		if vim.notify then
			vim.notify(msg, vim.log.levels[string.upper(level)], {
				title = "pathtool",
				timeout = opts.timeout or config.get("notification_timeout"),
			})
		else
			local levels = { INFO = "", WARN = "WARNING: ", ERROR = "ERROR: " }
			print(levels[string.upper(level)] .. msg)
		end
	end
end

--- Gets the absolute path of the current file
-- @return string|nil Absolute path or nil if no file is open
function M.get_absolute_path()
	local filename = vim.fn.expand("%:p")
	if filename == "" then
		M.notify("No file open", "warn")
		return nil
	end

	filename = utils.normalize_path(filename)
	return filename
end

--- Gets the relative path of the current file from the current working directory
-- @return string|nil Relative path or nil if no file is open
function M.get_relative_path()
	local filename = vim.fn.expand("%:.")
	if filename == "" then
		M.notify("No file open", "warn")
		return nil
	end

	filename = utils.normalize_path(filename)
	return filename
end

--- Cache for project root directories to avoid repeated lookups
local project_root_cache = {}

--- Finds the project root directory based on marker files/directories
-- @param force_refresh boolean (optional) Whether to ignore the cache and refresh
-- @return string Project root directory or current working directory if not found
function M.find_project_root(force_refresh)
	if not config.get("detect_project_root") then
		return vim.fn.getcwd()
	end

	local current_dir = vim.fn.expand("%:p:h")
	if current_dir == "" then
		current_dir = vim.fn.getcwd()
	end

	if not force_refresh and project_root_cache[current_dir] then
		return project_root_cache[current_dir]
	end

	for _, marker in ipairs(config.get("project_markers")) do
		local result = vim.fn.finddir(marker, current_dir .. ";")
		if result ~= "" then
			local root = vim.fn.fnamemodify(result, ":p:h:h")
			project_root_cache[current_dir] = root
			return root
		end

		result = vim.fn.findfile(marker, current_dir .. ";")
		if result ~= "" then
			local root = vim.fn.fnamemodify(result, ":p:h")
			project_root_cache[current_dir] = root
			return root
		end
	end

	project_root_cache[current_dir] = current_dir
	return current_dir
end

--- Gets the path of the current file relative to the project root
-- @return string|nil Project-relative path or nil if no file is open
function M.get_project_relative_path()
	local abs_path = M.get_absolute_path()
	if not abs_path then
		return nil
	end

	local root = M.find_project_root()
	if not root then
		M.notify("Project root not found", "warn")
		return abs_path
	end

	local rel_path = utils.path_relative_to(abs_path, root)
	return rel_path
end

--- Gets the filename of the current file
-- @return string|nil Filename or nil if no file is open
function M.get_filename()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		M.notify("No file open", "warn")
		return nil
	end
	return filename
end

--- Gets the filename without extension of the current file
-- @return string|nil Filename without extension or nil if no file is open
function M.get_filename_without_ext()
	local filename = vim.fn.expand("%:t:r")
	if filename == "" then
		M.notify("No file open", "warn")
		return nil
	end
	return filename
end

--- Gets the directory path of the current file
-- @return string|nil Directory path or nil if no file is open
function M.get_dirname()
	local dirname = vim.fn.expand("%:p:h")
	if dirname == "" then
		M.notify("No file open", "warn")
		return nil
	end

	dirname = utils.normalize_path(dirname)
	return dirname
end

--- Converts the path style of the current file (Unix ↔ Windows)
-- @return string|nil Converted path or nil if no file is open
function M.convert_path_style()
	local path = M.get_absolute_path()
	if not path then
		return nil
	end

	return utils.convert_path_style(path)
end

--- Encodes the current file path as a file URL
-- @return string|nil File URL or nil if no file is open
function M.encode_path_as_url()
	local path = M.get_absolute_path()
	if not path then
		return nil
	end

	local file_url = utils.path_to_file_url(path)
	return file_url
end

--- Copies a text string to clipboard
-- @param text string Text to copy
-- @param type string (optional) Action type for notification (default: "Copied")
-- @return boolean Whether the copying was successful
function M.copy_to_clipboard(text, type)
	if not text then
		return false
	end

	if config.get("use_system_clipboard") then
		vim.fn.setreg("+", text)
	end
	vim.fn.setreg('"', text)

	local display_text = text
	local max_len = config.get("path_display_length")
	local truncation_style = config.get("truncation_style") or "middle"

	if #text > max_len then
		if truncation_style == "start" then
			display_text = "..." .. string.sub(text, -max_len + 3)
		elseif truncation_style == "end" then
			display_text = string.sub(text, 1, max_len - 3) .. "..."
		else
			local part_len = math.floor((max_len - 3) / 2)
			display_text = string.sub(text, 1, part_len) .. "..." .. string.sub(text, -part_len)
		end
	end

	local action = type or "Copied"
	local format = config.get("notification_format") or "{action}: {path}"
	local msg = format:gsub("{action}", action):gsub("{path}", display_text)

	M.notify(msg, "info")
	return true
end

--- Gets a table with all available path formats for the current file
-- @return table Table with all path information or empty table if no file is open
function M.get_all_paths()
	local abs_path = M.get_absolute_path()
	if not abs_path then
		return {}
	end

	return {
		["Absolute Path"] = abs_path,
		["Relative Path"] = M.get_relative_path() or "N/A",
		["Project Path"] = M.get_project_relative_path() or "N/A",
		["Filename"] = M.get_filename() or "N/A",
		["Filename (no ext)"] = M.get_filename_without_ext() or "N/A",
		["Directory"] = M.get_dirname() or "N/A",
		["Converted Style"] = M.convert_path_style() or "N/A",
		["File URL"] = M.encode_path_as_url() or "N/A",
	}
end

return M
