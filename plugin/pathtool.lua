if vim.g.loaded_pathtool == 1 then
	return
end
vim.g.loaded_pathtool = 1

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
			no_default_mappings = vim.g.pathtool_no_default_mappings == 1,
			mapping_prefix = vim.g.pathtool_mapping_prefix or "<Leader>p",
		}

		local user_config = vim.g.pathtool_config or {}

		require("pathtool").setup(vim.tbl_deep_extend("force", default_config, user_config))
	end, 0)
end

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

local function create_default_mappings()
	if vim.g.pathtool_no_default_mappings == 1 then
		return
	end

	local prefix = vim.g.pathtool_mapping_prefix or "<Leader>p"

	local mappings = {
		{ key = "a", cmd = "PathCopyAbsolute", desc = "Copy absolute path" },
		{ key = "r", cmd = "PathCopyRelative", desc = "Copy relative path" },
		{ key = "p", cmd = "PathCopyProject", desc = "Copy project relative path" },
		{ key = "f", cmd = "PathCopyFilename", desc = "Copy filename" },
		{ key = "n", cmd = "PathCopyFilenameNoExt", desc = "Copy filename without extension" },
		{ key = "d", cmd = "PathCopyDirname", desc = "Copy directory path" },
		{ key = "c", cmd = "PathConvertStyle", desc = "Convert path style" },
		{ key = "u", cmd = "PathToUrl", desc = "Convert to file URL" },
		{ key = "o", cmd = "PathPreview", desc = "Open path preview" },
	}

	for _, mapping in ipairs(mappings) do
		vim.keymap.set("n", prefix .. mapping.key, ":" .. mapping.cmd .. "<CR>", { silent = true, desc = mapping.desc })
	end
end

create_commands()
create_default_mappings()
defer_setup()
