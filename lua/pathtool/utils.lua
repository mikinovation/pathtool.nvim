local M = {}

--- Determines if the current system is Windows
-- @return boolean True if the system is Windows
function M.is_windows()
	return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

--- Determines if the current system is Unix
-- @return boolean True if the system is Unix
function M.is_unix()
	return vim.fn.has("unix") == 1
end

--- Determines if the current system is macOS
-- @return boolean True if the system is macOS
function M.is_macos()
	return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
end

--- Checks if a path uses Windows path style
-- @param path string Path to check
-- @return boolean True if path is a Windows-style path
function M.is_windows_path(path)
	return path:match("\\") ~= nil or path:match("^%a:") ~= nil
end

--- Checks if a path uses Unix path style
-- @param path string Path to check
-- @return boolean True if path is a Unix-style path
function M.is_unix_path(path)
	return path:match("/") ~= nil and not M.is_windows_path(path)
end

--- Converts a path to the native path format for the current system
-- @param path string Path to convert
-- @return string Path converted to the native format for the current OS
function M.to_native_path(path)
	if M.is_windows() then
		if M.is_unix_path(path) then
			return path:gsub("/", "\\")
		end
	else
		if M.is_windows_path(path) then
			path = path:gsub("^(%a):", function(drive)
				return "/" .. string.lower(drive)
			end)
			return path:gsub("\\", "/")
		end
	end
	return path
end

--- Converts a path between Windows and Unix styles
-- @param path string Path to convert
-- @return string Path converted to the opposite style (Windows to Unix or Unix to Windows)
function M.convert_path_style(path)
	if M.is_windows_path(path) then
		path = path:gsub("\\", "/")
		path = path:gsub("^(%a):", function(drive)
			return "/" .. string.lower(drive)
		end)
		return path
	else
		local current_drive = string.upper(string.sub(vim.fn.getcwd(), 1, 1))

		local drive, rest = path:match("^/(%a)(.*)")
		if drive and rest then
			path = string.upper(drive) .. ":" .. rest
		elseif path:sub(1, 1) == "/" then
			path = current_drive .. ":" .. path
		end

		return path:gsub("/", "\\")
	end
end

--- Normalizes a path by removing trailing slashes and collapsing multiple consecutive slashes
-- @param path string Path to normalize
-- @return string|nil Normalized path or nil if input was nil
function M.normalize_path(path)
	if not path then
		return nil
	end

	path = path:gsub("[/\\]+$", "")

	path = path:gsub("([/\\])%1+", "%1")

	return path
end

--- URL encodes a string
-- @param str string String to URL encode
-- @return string|nil URL encoded string or nil if input was nil
function M.url_encode(str)
	if not str then
		return nil
	end

	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w%-%.%_%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)

	return str
end

--- Converts a path to a file URL
-- @param path string Path to convert
-- @return string|nil File URL representation of the path or nil if input was nil
function M.path_to_file_url(path)
	if not path then
		return nil
	end

	path = M.normalize_path(path)

	if M.is_windows_path(path) then
		path = path:gsub("\\", "/")

		if path:match("^%a:") then
			path = "/" .. path
		end
	end

	local encoded_path = ""
	for segment in path:gmatch("([^/]+)") do
		if encoded_path ~= "" then
			encoded_path = encoded_path .. "/"
		end
		encoded_path = encoded_path .. M.url_encode(segment)
	end

	if path:sub(1, 1) == "/" then
		encoded_path = "/" .. encoded_path
	end

	return "file://" .. encoded_path
end

--- Gets a path relative to a base path
-- @param path string The path to convert to relative
-- @param base string The base path to make the path relative to
-- @return string Either the relative path or the original path if it's not under the base path
function M.path_relative_to(path, base)
	if not path or not base then
		return path
	end

	path = M.normalize_path(path)
	base = M.normalize_path(base)

	local separator = M.is_windows() and "\\" or "/"

	local norm_path = path:gsub("[/\\]", separator)
	local norm_base = base:gsub("[/\\]", separator)

	if norm_path:sub(1, #norm_base) == norm_base then
		local rel_path = norm_path:sub(#norm_base + 1)
		rel_path = rel_path:gsub("^[/\\]", "")

		return rel_path ~= "" and rel_path or "."
	end

	return path
end

--- Changes the file extension of a path
-- @param path string The path whose extension should be changed
-- @param new_ext string The new extension (with or without leading dot)
-- @return string|nil The path with the new extension or nil if input was nil
function M.change_extension(path, new_ext)
	if not path then
		return nil
	end

	if new_ext and new_ext:sub(1, 1) ~= "." then
		new_ext = "." .. new_ext
	end

	local base = vim.fn.fnamemodify(path, ":r")
	return base .. (new_ext or "")
end

--- Gets a parent directory path
-- @param path string The path to get the parent of
-- @param levels number (optional) How many levels to go up (default: 1)
-- @return string|nil The parent path or nil if input was nil
function M.path_up(path, levels)
	if not path then
		return nil
	end
	levels = levels or 1

	local result = path
	for _ = 1, levels do
		result = vim.fn.fnamemodify(result, ":h")
	end

	return result
end

--- Joins two paths together
-- @param path1 string First path
-- @param path2 string Second path
-- @return string|nil The joined path or one of the inputs if the other is nil
function M.join_paths(path1, path2)
	if not path1 or not path2 then
		return path1 or path2
	end

	path1 = M.normalize_path(path1)

	local separator = "/"
	if M.is_windows_path(path1) then
		separator = "\\"
	end

	if path2:match("^/") or path2:match("^%a:") then
		return path2
	end

	if path1:sub(-1) ~= "/" and path1:sub(-1) ~= "\\" then
		path1 = path1 .. separator
	end

	return path1 .. path2
end

--- Creates a display-friendly version of a path, truncating if needed
-- @param path string The path to format for display
-- @param max_length number (optional) Maximum length for the displayed path (default: 60)
-- @return string|nil The formatted path or nil if input was nil
function M.safe_display_path(path, max_length)
	if not path then
		return nil
	end
	max_length = max_length or 60

	if #path <= max_length then
		return path
	end

	local separator = M.is_windows_path(path) and "\\" or "/"

	local parts = {}
	for part in path:gmatch("[^/\\]+") do
		table.insert(parts, part)
	end

	if #parts > 3 then
		local result = parts[1] .. separator .. "..." .. separator .. parts[#parts - 1] .. separator .. parts[#parts]

		if #result > max_length then
			result = "..." .. path:sub(-max_length + 3)
		end

		return result
	end

	return "..." .. path:sub(-max_length + 3)
end

return M
