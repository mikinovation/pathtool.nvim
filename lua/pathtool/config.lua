local M = {}

--- Default configuration values
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
	directory_files = {
		max_files = 1000,
		max_depth = 5,
		ignored_patterns = {
			"%.git",
			"node_modules",
			"%.DS_Store",
			"%.cache",
			"build",
			"dist",
		},
		include_directories = false,
		relative_paths = true,
	},
	notification_format = "{action}: {path}",
	truncation_style = "middle",
	disabled_features = {},
}

--- Current configuration
M.options = {}

--- Deep merges two tables recursively
-- @param dst table Destination table
-- @param src table Source table
-- @return table Merged table
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

--- Sets up the configuration
-- @param opts table|nil User options to merge with defaults
function M.setup(opts)
	M.options = {}
	M.options = deep_extend(M.options, M.defaults)

	if opts then
		M.options = deep_extend(M.options, opts)
	end
end

--- Gets a configuration value
-- @param key string|nil Configuration key to retrieve (returns full config if nil)
-- @return any Configuration value or full configuration table
function M.get(key)
	if key then
		return M.options[key]
	end
	return M.options
end

--- Checks if a feature is enabled
-- @param feature_name string Feature name to check
-- @return boolean Whether the feature is enabled
function M.is_feature_enabled(feature_name)
	local disabled = M.options.disabled_features or {}
	for _, v in ipairs(disabled) do
		if v == feature_name then
			return false
		end
	end
	return true
end

return M
