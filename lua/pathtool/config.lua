local M = {}

M.defaults = {
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
	notification_format = "{action}: {path}",
	truncation_style = "middle",
	disabled_features = {},
}

M.options = {}

local function deep_extend(dst, src)
	if type(dst) ~= "table" or type(src) ~= "table" then
		return src
	end

	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			dst[k] = deep_extend(dst[k], v)
		else
			dst[k] = v
		end
	end

	return dst
end

M.setup = function(opts)
	M.options = {}
	M.options = deep_extend(M.options, M.defaults)

	if opts then
		M.options = deep_extend(M.options, opts)
	end
end

M.get = function(key)
	if key then
		return M.options[key]
	end
	return M.options
end

M.is_feature_enabled = function(feature_name)
	local disabled = M.options.disabled_features or {}
	for _, v in ipairs(disabled) do
		if v == feature_name then
			return false
		end
	end
	return true
end

return M
