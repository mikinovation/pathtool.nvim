if vim.g.loaded_pathtool == 1 then
	return
end
vim.g.loaded_pathtool = 1

local function create_commands()
	vim.api.nvim_create_user_command("PathCopyAbsolute", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_absolute_path())
	end, { desc = "Copy absolute path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyRelative", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_relative_path())
	end, { desc = "Copy relative path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyProject", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_project_relative_path())
	end, { desc = "Copy project relative path to clipboard" })

	vim.api.nvim_create_user_command("PathCopyFilename", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_filename())
	end, { desc = "Copy filename to clipboard" })

	vim.api.nvim_create_user_command("PathCopyFilenameNoExt", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_filename_without_ext())
	end, { desc = "Copy filename without extension to clipboard" })

	vim.api.nvim_create_user_command("PathCopyDirname", function()
		require("pathtool").copy_to_clipboard(require("pathtool").get_dirname())
	end, { desc = "Copy directory path to clipboard" })

	vim.api.nvim_create_user_command("PathConvertStyle", function()
		require("pathtool").copy_to_clipboard(require("pathtool").convert_path_style())
	end, { desc = "Convert and copy path between Unix/Windows style" })

	vim.api.nvim_create_user_command("PathToUrl", function()
		require("pathtool").copy_to_clipboard(require("pathtool").encode_path_as_url())
	end, { desc = "Convert path to file URL and copy" })

	vim.api.nvim_create_user_command("PathPreview", function()
		require("pathtool").show_path_preview()
	end, { desc = "Show path preview window" })
end

local function create_default_mappings()
	if vim.g.pathtool_no_default_mappings == 1 then
		return
	end

	local prefix = vim.g.pathtool_mapping_prefix or "<Leader>p"

	vim.keymap.set("n", prefix .. "a", ":PathCopyAbsolute<CR>", { silent = true, desc = "Copy absolute path" })
	vim.keymap.set("n", prefix .. "r", ":PathCopyRelative<CR>", { silent = true, desc = "Copy relative path" })
	vim.keymap.set("n", prefix .. "p", ":PathCopyProject<CR>", { silent = true, desc = "Copy project relative path" })
	vim.keymap.set("n", prefix .. "f", ":PathCopyFilename<CR>", { silent = true, desc = "Copy filename" })
	vim.keymap.set(
		"n",
		prefix .. "n",
		":PathCopyFilenameNoExt<CR>",
		{ silent = true, desc = "Copy filename without extension" }
	)
	vim.keymap.set("n", prefix .. "d", ":PathCopyDirname<CR>", { silent = true, desc = "Copy directory path" })
	vim.keymap.set("n", prefix .. "c", ":PathConvertStyle<CR>", { silent = true, desc = "Convert path style" })
	vim.keymap.set("n", prefix .. "u", ":PathToUrl<CR>", { silent = true, desc = "Convert to file URL" })
	vim.keymap.set("n", prefix .. "o", ":PathPreview<CR>", { silent = true, desc = "Open path preview" })
end

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

create_commands()

create_default_mappings()

defer_setup()
