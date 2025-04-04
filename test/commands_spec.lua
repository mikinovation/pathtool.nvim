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
			is_feature_enabled = function()
				return true
			end,
		})

		stub(vim.api, "nvim_create_user_command")

		package.loaded["pathtool.core"] = core_mock
		package.loaded["pathtool.ui"] = ui_mock
		package.loaded["pathtool.config"] = config_mock

		commands = require("pathtool.commands")
	end)

	after_each(function()
		vim.api.nvim_create_user_command:revert()

		mock.revert(core_mock)
		mock.revert(ui_mock)
		mock.revert(config_mock)
	end)

	describe("setup", function()
		it("should register the expected commands", function()
			commands.setup()

			assert.stub(vim.api.nvim_create_user_command).was.called(11)

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
				"PathCopyDirectoryFiles",
			}

			for _, cmd_name in ipairs(expected_commands) do
				assert.stub(vim.api.nvim_create_user_command).was.called_with(cmd_name, match._, match._)
			end
		end)

		it("should check feature enablement", function()
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.returns(true)

			commands.setup()

			assert.stub(config_mock.is_feature_enabled).was.called(11)

			mock.revert(config_mock.is_feature_enabled)
		end)

		it("should not register disabled commands", function()
			stub(config_mock, "is_feature_enabled")
			config_mock.is_feature_enabled.on_call_with("PathCopyAbsolute").returns(false)
			config_mock.is_feature_enabled.on_call_with(match.not_equals("PathCopyAbsolute")).returns(true)

			commands.setup()

			assert.stub(vim.api.nvim_create_user_command).was.called(10)

			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				assert.not_equals("PathCopyAbsolute", call.refs[1])
			end

			mock.revert(config_mock.is_feature_enabled)
		end)
	end)

	describe("command callbacks", function()
		it("should call core functions when commands are executed", function()
			stub(core_mock, "copy_to_clipboard")
			stub(core_mock, "get_absolute_path")

			commands.setup()

			local absolute_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathCopyAbsolute" then
					absolute_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(absolute_cmd_callback)

			absolute_cmd_callback()

			assert.stub(core_mock.get_absolute_path).was.called(1)
			assert.stub(core_mock.copy_to_clipboard).was.called(1)

			mock.revert(core_mock.copy_to_clipboard)
			mock.revert(core_mock.get_absolute_path)
		end)

		it("should call ui functions for preview command", function()
			stub(ui_mock, "show_path_preview")

			commands.setup()

			local preview_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathPreview" then
					preview_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(preview_cmd_callback)

			preview_cmd_callback()

			assert.stub(ui_mock.show_path_preview).was.called(1)

			mock.revert(ui_mock.show_path_preview)
		end)

		it("should call project root refresh for PathRefreshRoot command", function()
			local original_find_project_root = core_mock.find_project_root
			core_mock.find_project_root = function()
				return "/home/user/projects/test"
			end

			stub(core_mock, "notify")

			commands.setup()

			local refresh_cmd_callback
			for i, call in ipairs(vim.api.nvim_create_user_command.calls) do
				if call.refs[1] == "PathRefreshRoot" then
					refresh_cmd_callback = call.refs[2]
					break
				end
			end

			assert.is_function(refresh_cmd_callback)

			refresh_cmd_callback()

			assert.stub(core_mock.notify).was.called(1)

			core_mock.find_project_root = original_find_project_root

			mock.revert(core_mock.find_project_root)
			mock.revert(core_mock.notify)
		end)
	end)
end)
