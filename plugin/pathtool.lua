--- pathtool.nvim plugin entry point
-- Sets up initial plugin loading and commands

-- Prevent loading the plugin multiple times
if vim.g.loaded_pathtool == 1 then
	return
end
vim.g.loaded_pathtool = 1

--- Defers plugin setup to allow other plugins to load first
local function defer_setup()
	vim.defer_fn(function()
		local default_config = {
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

		local user_config = vim.g.pathtool_config or {}

		require("pathtool").setup(vim.tbl_deep_extend("force", default_config, user_config))
	end, 0)
end

--- Creates Neovim commands that load the plugin on first use
local function create_commands()
	for _, cmd_name in ipairs({
		"PathCopyAbsolute",
		"PathCopyRelative",
		"PathCopyProject",
		"PathCopyFilename",
		"PathCopyFilenameNoExt",
		"PathCopyDirname",
		"PathConvertStyle",
		"PathToUrl",
		"PathPreview",
		"PathRefreshRoot",
	}) do
		vim.api.nvim_create_user_command(cmd_name, function()
			require("pathtool")
			vim.cmd(cmd_name)
		end, {})
	end
end

-- Create the commands and set up the plugin
create_commands()
defer_setup()
