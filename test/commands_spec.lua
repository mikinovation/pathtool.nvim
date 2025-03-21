local mock = require("luassert.mock")
local stub = require("luassert.stub")

_G.vim = {
	api = {
		nvim_create_user_command = function() end,
	},
	keymap = {
		set = function() end,
	},
	g = {},
	cmd = function() end,
}

describe("pathtool.commands", function()
	local commands
	local core_mock
	local ui_mock
	local config_mock

	before_each(function()
		package.loaded["pathtool.commands"] = nil
		package.loaded["pathtool.core"] = nil
		package.loaded["pathtool.ui"] = nil
		package.loaded["pathtool.config"] = nil

		-- Mock the dependencies
		core_mock = mock({
			copy_to_clipboard = function() end,
			get_absolute_path = function()
				return "/home/user/projects/test/file.txt"
			end,
			get_relative_path = function()
				return "test/file.txt"
			end,
			get_project_relative_path = function()
				return "file.txt"
			end,
			get_filename = function()
				return "file.txt"
			end,
			get_filename_without_ext = function()
				return "file"
			end,
			get_dirname = function()
				return "/home/user/projects/test"
			end,
			convert_path_style = function()
				return "\\home\\user\\projects\\test\\file.txt"
			end,
			encode_path_as_url = function()
				return "file:///home/user/projects/test/file.txt"
			end,
			find_project_root = function()
				return "/home/user/projects/test"
			end,
			notify = function() end,
		})

		ui_mock = mock({
			show_path_preview = function() end,
		})

		config_mock = mock({
			get = function(key)
				if key == "keymaps" then
					return {
						copy_absolute_path = "<leader>pa",
						copy_relative_path = "<leader>pr",
						copy_project_path = "<leader>pp",
						copy_filename = "<leader>pf",
						copy_filename_no_ext = "<leader>pn",
						copy_dirname = "<leader>pd",
						convert_path_style = "<leader>pc",
						convert_to_url = "<leader>pu",
						open_preview = "<leader>po",
					}
				elseif key == "no_default_mappings" then
					return false
				end
				return nil
			end,
			is_feature_enabled = function(feature_name)
				return true
			end,
		})

		-- Create stubs for the Vim API calls
		stub(vim.api, "nvim_create_user_command")
		stub(vim.keymap, "set")

		-- Set up our mocked dependencies
		package.loaded["pathtool.core"] = core_mock
		package.loaded["pathtool.ui"] = ui_mock
		package.loaded["pathtool.config"] = config_mock

		-- Finally load the module we're testing
		commands = require("pathtool.commands")
	end)

	after_each(function()
		vim.api.nvim_create_user_command:revert()
		vim.keymap.set:revert()

		mock.revert(core_mock)
		mock.revert(ui_mock)
		mock.revert(config_mock)
	end)

	describe("setup", function()
		it("should register the expected commands", function()
			commands.setup()

			assert.stub(vim.api.nvim_create_user_command).was.called(10)

			-- Check for each specific command being registered
			local expected_commands = {
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
			}

			for _, cmd_name in ipairs(expected_commands) do
				assert.stub(vim.api.nvim_create_user_command).was.called_with(cmd_name, match._, match._)
			end
		end)

		it("should check feature enablement", function()
			-- Set up our mock to track calls to is_feature_enabled
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.returns(true)

			commands.setup()

			-- We should check feature enablement for each command
			assert.stub(config_mock.is_feature_enabled).was.called(10)

			mock.revert(config_mock.is_feature_enabled)
		end)

		it("should not register disabled commands", function()
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.on_call_with("PathCopyAbsolute").returns(false)
			config_mock.is_feature_enabled.on_call_with(match.not_equals("PathCopyAbsolute")).returns(true)

			commands.setup()

			-- Now we should have one less command registered
			assert.stub(vim.api.nvim_create_user_command).was.called(9)

			-- Specifically, PathCopyAbsolute should not be called
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				assert.not_equals("PathCopyAbsolute", call.refs[1])
			end

			mock.revert(config_mock.is_feature_enabled)
		end)
	end)

	describe("setup_keymaps", function()
		it("should register default keymaps", function()
			commands.setup_keymaps()

			-- Should set up 9 keymaps
			assert.stub(vim.keymap.set).was.called(9)
		end)

		it("should not set up keymaps when no_default_mappings is true", function()
			stub(config_mock, "get")
			config_mock.get.on_call_with("no_default_mappings").returns(true)

			commands.setup_keymaps()

			assert.stub(vim.keymap.set).was_not.called()

			mock.revert(config_mock.get)
		end)

		it("should use the configured keymap prefixes", function()
			stub(config_mock, "get")
			config_mock.get.on_call_with("no_default_mappings").returns(false)
			config_mock.get.on_call_with("keymaps").returns({
				copy_absolute_path = "<leader>ca",
				copy_relative_path = "<leader>cr",
				copy_project_path = "<leader>cp",
				copy_filename = "<leader>cf",
				copy_filename_no_ext = "<leader>cn",
				copy_dirname = "<leader>cd",
				convert_path_style = "<leader>cc",
				convert_to_url = "<leader>cu",
				open_preview = "<leader>co",
			})

			commands.setup_keymaps()

			assert.stub(vim.keymap.set).was.called(9)

			-- Check a few specific keymaps
			assert.stub(vim.keymap.set).was.called_with("n", "<leader>ca", match._, match._)

			assert.stub(vim.keymap.set).was.called_with("n", "<leader>cf", match._, match._)

			mock.revert(config_mock.get)
		end)

		it("should check feature enablement for each keymap", function()
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.returns(true)

			commands.setup_keymaps()

			-- Should check 9 features
			assert.stub(config_mock.is_feature_enabled).was.called(9)

			mock.revert(config_mock.is_feature_enabled)
		end)

		it("should not register disabled keymaps", function()
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.on_call_with("copy_absolute_path").returns(false)
			config_mock.is_feature_enabled.on_call_with(match.not_equals("copy_absolute_path")).returns(true)

			commands.setup_keymaps()

			-- Should have one less keymap
			assert.stub(vim.keymap.set).was.called(8)

			-- The "<leader>pa" keymap should not be registered
			for i, call in ipairs(vim.keymap.set.calls) do
				assert.not_equals("<leader>pa", call.refs[2])
			end

			mock.revert(config_mock.is_feature_enabled)
		end)

		it("should not register keymaps with nil keys", function()
			stub(config_mock, "get")
			config_mock.get.on_call_with("no_default_mappings").returns(false)
			config_mock.get.on_call_with("keymaps").returns({
				copy_absolute_path = "<leader>pa",
				copy_relative_path = nil, -- This one should be skipped
				copy_project_path = "<leader>pp",
				copy_filename = "<leader>pf",
				copy_filename_no_ext = "<leader>pn",
				copy_dirname = "<leader>pd",
				convert_path_style = "<leader>pc",
				convert_to_url = "<leader>pu",
				open_preview = "<leader>po",
			})

			commands.setup_keymaps()

			-- Should have one less keymap
			assert.stub(vim.keymap.set).was.called(8)

			mock.revert(config_mock.get)
		end)
	end)

	describe("command callbacks", function()
		it("should call core functions when commands are executed", function()
			stub(core_mock, "copy_to_clipboard")
			stub(core_mock, "get_absolute_path")

			-- Set up the commands
			commands.setup()

			-- Simulate running a command by finding and calling its callback
			local absolute_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathCopyAbsolute" then
					absolute_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(absolute_cmd_callback)

			-- Call the PathCopyAbsolute command callback
			absolute_cmd_callback()

			-- Verify the core functions were called
			assert.stub(core_mock.get_absolute_path).was.called(1)
			assert.stub(core_mock.copy_to_clipboard).was.called(1)

			mock.revert(core_mock.copy_to_clipboard)
			mock.revert(core_mock.get_absolute_path)
		end)

		it("should call ui functions for preview command", function()
			stub(ui_mock, "show_path_preview")

			-- Set up the commands
			commands.setup()

			-- Find and call the PathPreview callback
			local preview_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathPreview" then
					preview_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(preview_cmd_callback)

			-- Call the PathPreview command callback
			preview_cmd_callback()

			-- Verify the UI function was called
			assert.stub(ui_mock.show_path_preview).was.called(1)

			mock.revert(ui_mock.show_path_preview)
		end)

		it("should call project root refresh for PathRefreshRoot command", function()
			-- Make find_project_root always return a valid path
			local original_find_project_root = core_mock.find_project_root
			core_mock.find_project_root = function(force_refresh)
				return "/home/user/projects/test"
			end

			stub(core_mock, "notify")

			-- Set up the commands
			commands.setup()

			-- Find and call the PathRefreshRoot callback
			local refresh_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathRefreshRoot" then
					refresh_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(refresh_cmd_callback)

			-- Call the PathRefreshRoot command callback
			refresh_cmd_callback()

			-- Verify the notify function was called
			assert.stub(core_mock.notify).was.called(1)

			-- Restore the original function
			core_mock.find_project_root = original_find_project_root

			mock.revert(core_mock.find_project_root)
			mock.revert(core_mock.notify)
		end)
	end)

	describe("keymap callbacks", function()
		it("should call core functions when keymaps are used", function()
			stub(core_mock, "copy_to_clipboard")
			stub(core_mock, "get_absolute_path")

			-- Set up the keymaps
			commands.setup_keymaps()

			-- Find and call a keymap callback
			local absolute_keymap_callback
			for i, call in ipairs(vim.keymap.set.calls) do
				if call.refs[2] == "<leader>pa" then
					absolute_keymap_callback = call.refs[3]
					break
				end
			end

			assert.is_function(absolute_keymap_callback)

			-- Call the absolute path keymap callback
			absolute_keymap_callback()

			-- Verify the core functions were called
			assert.stub(core_mock.get_absolute_path).was.called(1)
			assert.stub(core_mock.copy_to_clipboard).was.called(1)

			mock.revert(core_mock.copy_to_clipboard)
			mock.revert(core_mock.get_absolute_path)
		end)

		it("should call ui functions for preview keymap", function()
			stub(ui_mock, "show_path_preview")

			-- Set up the keymaps
			commands.setup_keymaps()

			-- Find and call the preview keymap callback
			local preview_keymap_callback
			for i, call in ipairs(vim.keymap.set.calls) do
				if call.refs[2] == "<leader>po" then
					preview_keymap_callback = call.refs[3]
					break
				end
			end

			assert.is_function(preview_keymap_callback)

			-- Call the preview keymap callback
			preview_keymap_callback()

			-- Verify the UI function was called
			assert.stub(ui_mock.show_path_preview).was.called(1)

			mock.revert(ui_mock.show_path_preview)
		end)
	end)
end)
