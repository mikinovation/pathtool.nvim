local M = {}

M.is_windows = function()
	return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

M.is_unix = function()
	return vim.fn.has("unix") == 1
end

M.is_macos = function()
	return vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
end

M.is_windows_path = function(path)
	return path:match("\\") ~= nil or path:match("^%a:") ~= nil
end

M.is_unix_path = function(path)
	return path:match("/") ~= nil and not M.is_windows_path(path)
end

M.to_native_path = function(path)
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

M.convert_path_style = function(path)
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

M.normalize_path = function(path)
	if not path then
		return nil
	end

	path = path:gsub("[/\\]+$", "")

	path = path:gsub("([/\\])%1+", "%1")

	return path
end

M.url_encode = function(str)
	if not str then
		return nil
	end

	str = str:gsub("\n", "\r\n")
	str = str:gsub("([^%w%-%.%_%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end)

	return str
end

M.path_to_file_url = function(path)
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

M.path_relative_to = function(path, base)
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

M.change_extension = function(path, new_ext)
	if not path then
		return nil
	end

	if new_ext and new_ext:sub(1, 1) ~= "." then
		new_ext = "." .. new_ext
	end

	local base = vim.fn.fnamemodify(path, ":r")
	return base .. (new_ext or "")
end

M.path_up = function(path, levels)
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

M.join_paths = function(path1, path2)
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

	-- パスを結合
	return path1 .. path2
end

M.safe_display_path = function(path, max_length)
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
