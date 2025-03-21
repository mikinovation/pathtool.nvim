local core = require("pathtool.core")
local ui = require("pathtool.ui")
local config = require("pathtool.config")

local M = {}

M.setup = function()
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
	}

	for _, cmd in ipairs(commands) do
		if config.is_feature_enabled(cmd.name) then
			vim.api.nvim_create_user_command(cmd.name, cmd.callback, { desc = cmd.desc })
		end
	end
end

M.setup_keymaps = function()
	if config.get("no_default_mappings") then
		return
	end

	local keymaps = config.get("keymaps")

	local keymap_configs = {
		{
			key = keymaps.copy_absolute_path,
			callback = function()
				core.copy_to_clipboard(core.get_absolute_path())
			end,
			desc = "Copy absolute path",
			feature = "copy_absolute_path",
		},
		{
			key = keymaps.copy_relative_path,
			callback = function()
				core.copy_to_clipboard(core.get_relative_path())
			end,
			desc = "Copy relative path",
			feature = "copy_relative_path",
		},
		{
			key = keymaps.copy_project_path,
			callback = function()
				core.copy_to_clipboard(core.get_project_relative_path())
			end,
			desc = "Copy project relative path",
			feature = "copy_project_path",
		},
		{
			key = keymaps.copy_filename,
			callback = function()
				core.copy_to_clipboard(core.get_filename())
			end,
			desc = "Copy filename",
			feature = "copy_filename",
		},
		{
			key = keymaps.copy_filename_no_ext,
			callback = function()
				core.copy_to_clipboard(core.get_filename_without_ext())
			end,
			desc = "Copy filename without extension",
			feature = "copy_filename_no_ext",
		},
		{
			key = keymaps.copy_dirname,
			callback = function()
				core.copy_to_clipboard(core.get_dirname())
			end,
			desc = "Copy directory path",
			feature = "copy_dirname",
		},
		{
			key = keymaps.convert_path_style,
			callback = function()
				core.copy_to_clipboard(core.convert_path_style())
			end,
			desc = "Convert path style",
			feature = "convert_path_style",
		},
		{
			key = keymaps.convert_to_url,
			callback = function()
				core.copy_to_clipboard(core.encode_path_as_url())
			end,
			desc = "Convert to file URL",
			feature = "convert_to_url",
		},
		{
			key = keymaps.open_preview,
			callback = function()
				ui.show_path_preview()
			end,
			desc = "Open path preview",
			feature = "open_preview",
		},
	}

	for _, keymap in ipairs(keymap_configs) do
		if keymap.key and config.is_feature_enabled(keymap.feature) then
			vim.keymap.set("n", keymap.key, keymap.callback, { desc = keymap.desc })
		end
	end
end

return M
