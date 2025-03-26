local core = require("pathtool.core")
local ui = require("pathtool.ui")
local config = require("pathtool.config")

local M = {}

--- Sets up the plugin commands
-- Creates user commands for all path operations if they are enabled in config
function M.setup()
	local commands = {
		{
			name = "PathCopyAbsolute",
			callback = function()
				core.copy_to_clipboard(core.get_absolute_path())
			end,
			desc = "Copy absolute path to clipboard",
		},
		{
			name = "PathCopyRelative",
			callback = function()
				core.copy_to_clipboard(core.get_relative_path())
			end,
			desc = "Copy relative path to clipboard",
		},
		{
			name = "PathCopyProject",
			callback = function()
				core.copy_to_clipboard(core.get_project_relative_path())
			end,
			desc = "Copy project relative path to clipboard",
		},
		{
			name = "PathCopyFilename",
			callback = function()
				core.copy_to_clipboard(core.get_filename())
			end,
			desc = "Copy filename to clipboard",
		},
		{
			name = "PathCopyFilenameNoExt",
			callback = function()
				core.copy_to_clipboard(core.get_filename_without_ext())
			end,
			desc = "Copy filename without extension to clipboard",
		},
		{
			name = "PathCopyDirname",
			callback = function()
				core.copy_to_clipboard(core.get_dirname())
			end,
			desc = "Copy directory path to clipboard",
		},
		{
			name = "PathConvertStyle",
			callback = function()
				core.copy_to_clipboard(core.convert_path_style())
			end,
			desc = "Convert and copy path between Unix/Windows style",
		},
		{
			name = "PathToUrl",
			callback = function()
				core.copy_to_clipboard(core.encode_path_as_url())
			end,
			desc = "Convert path to file URL and copy",
		},
		{
			name = "PathPreview",
			callback = function()
				ui.show_path_preview()
			end,
			desc = "Show path preview window",
		},
		{
			name = "PathRefreshRoot",
			callback = function()
				local root = core.find_project_root(true)
				core.notify("Project root refreshed: " .. root, "info")
			end,
			desc = "Refresh project root cache",
		},
		{
			name = "PathCopyDirectoryFiles",
			callback = function()
				core.copy_to_clipboard(core.get_directory_files())
			end,
			desc = "Copy all file paths in directory to clipboard",
		},
	}

	for _, cmd in ipairs(commands) do
		if config.is_feature_enabled(cmd.name) then
			vim.api.nvim_create_user_command(cmd.name, cmd.callback, { desc = cmd.desc })
		end
	end
end

return M
