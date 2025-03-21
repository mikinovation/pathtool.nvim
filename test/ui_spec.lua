local mock = require("luassert.mock")
local stub = require("luassert.stub")

_G.vim = {
	api = {
		nvim_create_buf = function()
			return 1
		end,
		nvim_buf_set_lines = function() end,
		nvim_open_win = function()
			return 2
		end,
		nvim_buf_set_option = function() end,
		nvim_win_set_option = function() end,
		nvim_buf_set_keymap = function() end,
		nvim_create_autocmd = function() end,
		nvim_win_close = function() end,
		nvim_win_is_valid = function()
			return true
		end,
	},
	cmd = function() end,
	o = {
		columns = 120,
		lines = 40,
	},
	fn = {
		has = function()
			return 1
		end,
	},
}

describe("pathtool.ui", function()
	local ui
	local config_mock
	local core_mock

	before_each(function()
		package.loaded["pathtool.ui"] = nil
		package.loaded["pathtool.config"] = nil
		package.loaded["pathtool.core"] = nil

		config_mock = mock({
			get = function(key)
				if key == "path_display_length" then
					return 60
				end
				return nil
			end,
		})

		core_mock = mock({
			get_all_paths = function()
				return {
					["Absolute Path"] = "/home/user/projects/test/file.txt",
					["Relative Path"] = "test/file.txt",
					["Project Path"] = "file.txt",
					["Filename"] = "file.txt",
					["Filename (no ext)"] = "file",
					["Directory"] = "/home/user/projects/test",
					["Converted Style"] = "\\home\\user\\projects\\test\\file.txt",
					["File URL"] = "file:///home/user/projects/test/file.txt",
				}
			end,
			copy_to_clipboard = function()
				return true
			end,
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
		})

		package.loaded["pathtool.config"] = config_mock
		package.loaded["pathtool.core"] = core_mock

		ui = require("pathtool.ui")
	end)

	after_each(function()
		mock.revert(config_mock)
		mock.revert(core_mock)
	end)

	describe("show_path_preview", function()
		it("should create a buffer and window", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			local create_buf_called = 0
			local open_win_called = 0
			local buf_set_lines_called = 0
			local buf_set_option_called = 0
			local win_set_option_called = 0
			local buf_set_keymap_called = 0
			local create_autocmd_called = 0
			local cmd_called = 0

			vim.api.nvim_create_buf = function()
				create_buf_called = create_buf_called + 1
				return 1
			end

			vim.api.nvim_open_win = function()
				open_win_called = open_win_called + 1
				return 2
			end

			vim.api.nvim_buf_set_lines = function()
				buf_set_lines_called = buf_set_lines_called + 1
			end

			vim.api.nvim_buf_set_option = function()
				buf_set_option_called = buf_set_option_called + 1
			end

			vim.api.nvim_win_set_option = function()
				win_set_option_called = win_set_option_called + 1
			end

			vim.api.nvim_buf_set_keymap = function()
				buf_set_keymap_called = buf_set_keymap_called + 1
			end

			vim.api.nvim_create_autocmd = function()
				create_autocmd_called = create_autocmd_called + 1
			end

			vim.cmd = function()
				cmd_called = cmd_called + 1
			end

			ui.show_path_preview()

			assert.equals(1, create_buf_called)
			assert.equals(1, open_win_called)
			assert.equals(1, buf_set_lines_called)
			assert.is_true(buf_set_option_called > 0)
			assert.is_true(win_set_option_called > 0)
			assert.is_true(buf_set_keymap_called > 0)
			assert.equals(1, create_autocmd_called)
			assert.equals(1, cmd_called)

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
		end)

		it("should call get_all_paths to populate window", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end
			vim.api.nvim_win_set_option = function() end
			vim.api.nvim_buf_set_keymap = function() end
			vim.api.nvim_create_autocmd = function() end
			vim.cmd = function() end

			local get_all_paths_called = 0
			local orig_get_all_paths = core_mock.get_all_paths

			core_mock.get_all_paths = function()
				get_all_paths_called = get_all_paths_called + 1
				return {
					["Absolute Path"] = "/home/user/projects/test/file.txt",
					["Relative Path"] = "test/file.txt",
				}
			end

			ui.show_path_preview()

			assert.equals(1, get_all_paths_called)

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
			core_mock.get_all_paths = orig_get_all_paths
		end)

		it("should setup keymaps for each path type", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			local keymaps_registered = {}

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end
			vim.api.nvim_win_set_option = function() end

			vim.api.nvim_buf_set_keymap = function(buf, mode, key, mapping, opts)
				keymaps_registered[key] = true
			end

			vim.api.nvim_create_autocmd = function() end
			vim.cmd = function() end

			ui.show_path_preview()

			local expected_keys = { "a", "r", "p", "f", "n", "d", "c", "u", "q", "<Esc>" }

			for _, key in ipairs(expected_keys) do
				assert.is_true(keymaps_registered[key], "Key " .. key .. " should be registered")
			end

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
		end)

		it("should setup autocmd to close window on BufLeave", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			local autocmd_registered = false
			local autocmd_events = nil
			local autocmd_buffer = nil

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end
			vim.api.nvim_win_set_option = function() end
			vim.api.nvim_buf_set_keymap = function() end

			vim.api.nvim_create_autocmd = function(events, opts)
				autocmd_registered = true
				autocmd_events = events
				autocmd_buffer = opts.buffer
			end

			vim.cmd = function() end

			ui.show_path_preview()

			assert.is_true(autocmd_registered)
			assert.is_table(autocmd_events)
			assert.equals("BufLeave", autocmd_events[1])
			assert.equals(1, autocmd_buffer)

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
		end)

		it("should set buffer options correctly", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			local buffer_options = {}

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end

			vim.api.nvim_buf_set_option = function(buf, option, value)
				buffer_options[option] = value
			end

			vim.api.nvim_win_set_option = function() end
			vim.api.nvim_buf_set_keymap = function() end
			vim.api.nvim_create_autocmd = function() end
			vim.cmd = function() end

			ui.show_path_preview()

			assert.equals(false, buffer_options["modifiable"])
			assert.equals("wipe", buffer_options["bufhidden"])

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
		end)

		it("should set window options correctly", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_cmd = vim.cmd

			local window_options = {}

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end

			vim.api.nvim_win_set_option = function(win, option, value)
				window_options[option] = value
			end

			vim.api.nvim_buf_set_keymap = function() end
			vim.api.nvim_create_autocmd = function() end
			vim.cmd = function() end

			ui.show_path_preview()

			assert.equals("Normal:pathtoolNormal,FloatBorder:pathtoolBorder", window_options["winhl"])

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.cmd = orig_cmd
		end)

		it("should handle keymap callbacks correctly", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_nvim_win_close = vim.api.nvim_win_close
			local orig_cmd = vim.cmd

			local captured_callbacks = {}

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end
			vim.api.nvim_win_set_option = function() end

			vim.api.nvim_buf_set_keymap = function(bufnr, mode, key, mapping, opts)
				captured_callbacks[key] = opts.callback
			end

			vim.api.nvim_create_autocmd = function() end
			vim.cmd = function() end

			local win_close_called = 0
			local win_close_args = {}

			vim.api.nvim_win_close = function(win, force)
				win_close_called = win_close_called + 1
				win_close_args = { win = win, force = force }
			end

			ui.show_path_preview()

			if captured_callbacks["a"] then
				local orig_get_absolute_path = core_mock.get_absolute_path
				local orig_copy_to_clipboard = core_mock.copy_to_clipboard
				local get_absolute_path_called = 0
				local copy_to_clipboard_called = 0
				local copy_to_clipboard_args = nil

				core_mock.get_absolute_path = function()
					get_absolute_path_called = get_absolute_path_called + 1
					return "/test/path.txt"
				end

				core_mock.copy_to_clipboard = function(text)
					copy_to_clipboard_called = copy_to_clipboard_called + 1
					copy_to_clipboard_args = text
					return true
				end

				captured_callbacks["a"]()

				assert.equals(1, get_absolute_path_called)
				assert.equals(1, copy_to_clipboard_called)
				assert.equals("/test/path.txt", copy_to_clipboard_args)
				assert.equals(1, win_close_called)
				assert.equals(2, win_close_args.win)
				assert.is_true(win_close_args.force)

				core_mock.get_absolute_path = orig_get_absolute_path
				core_mock.copy_to_clipboard = orig_copy_to_clipboard
			end

			if captured_callbacks["q"] then
				win_close_called = 0
				win_close_args = {}

				captured_callbacks["q"]()

				assert.equals(1, win_close_called)
				assert.equals(2, win_close_args.win)
				assert.is_true(win_close_args.force)
			end

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.api.nvim_win_close = orig_nvim_win_close
			vim.cmd = orig_cmd
		end)

		it("should handle BufLeave autocmd correctly", function()
			local orig_nvim_create_buf = vim.api.nvim_create_buf
			local orig_nvim_open_win = vim.api.nvim_open_win
			local orig_nvim_buf_set_lines = vim.api.nvim_buf_set_lines
			local orig_nvim_buf_set_option = vim.api.nvim_buf_set_option
			local orig_nvim_win_set_option = vim.api.nvim_win_set_option
			local orig_nvim_buf_set_keymap = vim.api.nvim_buf_set_keymap
			local orig_nvim_create_autocmd = vim.api.nvim_create_autocmd
			local orig_nvim_win_is_valid = vim.api.nvim_win_is_valid
			local orig_nvim_win_close = vim.api.nvim_win_close
			local orig_cmd = vim.cmd

			local autocmd_callback = nil

			vim.api.nvim_create_buf = function()
				return 1
			end
			vim.api.nvim_open_win = function()
				return 2
			end
			vim.api.nvim_buf_set_lines = function() end
			vim.api.nvim_buf_set_option = function() end
			vim.api.nvim_win_set_option = function() end
			vim.api.nvim_buf_set_keymap = function() end

			vim.api.nvim_create_autocmd = function(events, opts)
				if events[1] == "BufLeave" then
					autocmd_callback = opts.callback
				end
			end

			vim.cmd = function() end

			local win_is_valid_called = 0
			local win_is_valid_args = nil
			local win_close_called = 0
			local win_close_args = {}

			vim.api.nvim_win_is_valid = function(win)
				win_is_valid_called = win_is_valid_called + 1
				win_is_valid_args = win
				return true
			end

			vim.api.nvim_win_close = function(win, force)
				win_close_called = win_close_called + 1
				win_close_args = { win = win, force = force }
			end

			ui.show_path_preview()

			if autocmd_callback then
				autocmd_callback()

				assert.equals(1, win_is_valid_called)
				assert.equals(2, win_is_valid_args)
				assert.equals(1, win_close_called)
				assert.equals(2, win_close_args.win)
				assert.is_true(win_close_args.force)
			end

			vim.api.nvim_create_buf = orig_nvim_create_buf
			vim.api.nvim_open_win = orig_nvim_open_win
			vim.api.nvim_buf_set_lines = orig_nvim_buf_set_lines
			vim.api.nvim_buf_set_option = orig_nvim_buf_set_option
			vim.api.nvim_win_set_option = orig_nvim_win_set_option
			vim.api.nvim_buf_set_keymap = orig_nvim_buf_set_keymap
			vim.api.nvim_create_autocmd = orig_nvim_create_autocmd
			vim.api.nvim_win_is_valid = orig_nvim_win_is_valid
			vim.api.nvim_win_close = orig_nvim_win_close
			vim.cmd = orig_cmd
		end)
	end)
end)
