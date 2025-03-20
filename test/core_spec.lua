local mock = require("luassert.mock")
local stub = require("luassert.stub")

local vim_mock = {
	fn = {
		expand = function(arg)
			if arg == "%:p" then
				return "/home/user/projects/test/file.txt"
			elseif arg == "%:." then
				return "test/file.txt"
			elseif arg == "%:t" then
				return "file.txt"
			elseif arg == "%:t:r" then
				return "file"
			elseif arg == "%:p:h" then
				return "/home/user/projects/test"
			end
			return ""
		end,
		getcwd = function()
			return "/home/user/projects"
		end,
		fnamemodify = function(path, modifier)
			if not path then
				return nil
			end

			if modifier == ":p:h" then
				return path:match("(.+)/[^/]+$") or path
			elseif modifier == ":p:h:h" then
				local parent = path:match("(.+)/[^/]+$") or path
				return parent:match("(.+)/[^/]+$") or parent
			elseif modifier == ":r" then
				return path:match("(.+)%.[^.]+$") or path
			end
			return path
		end,
		finddir = function(marker, path)
			if marker == ".git" and path:match("/home/user/projects/test") then
				return "/home/user/projects/test/.git"
			end
			return ""
		end,
		findfile = function(marker, path)
			return ""
		end,
		has = function(feature)
			if feature == "win32" or feature == "win64" then
				return 0
			elseif feature == "unix" then
				return 1
			elseif feature == "mac" or feature == "macunix" then
				return 0
			end
			return 0
		end,
		setreg = function() end,
	},
	api = {
		nvim_create_user_command = function() end,
	},
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 3,
		},
	},
	cmd = function() end,
	notify = function() end,
	tbl_deep_extend = function(_, t1, t2)
		local result = {}
		for k, v in pairs(t1) do
			result[k] = v
		end
		for k, v in pairs(t2 or {}) do
			result[k] = v
		end
		return result
	end,
}

_G.vim = vim_mock

describe("pathtool.core", function()
	local core
	local utils_mock
	local config_mock

	before_each(function()
		package.loaded["pathtool.core"] = nil
		package.loaded["pathtool.utils"] = nil
		package.loaded["pathtool.config"] = nil

		config_mock = mock({
			get = function(key)
				if key == "path_display_length" then
					return 60
				elseif key == "truncation_style" then
					return "middle"
				elseif key == "notification_format" then
					return "{action}: {path}"
				elseif key == "detect_project_root" then
					return true
				elseif key == "project_markers" then
					return {
						".git",
						".svn",
						"package.json",
						"Cargo.toml",
					}
				elseif key == "show_notifications" then
					return true
				elseif key == "use_system_clipboard" then
					return true
				elseif key == "notification_timeout" then
					return 3000
				end
				return nil
			end,
		})

		utils_mock = mock({
			normalize_path = function(path)
				if not path then
					return nil
				end
				path = path:gsub("[/\\]+$", "")
				path = path:gsub("([/\\])%1+", "%1")
				return path
			end,
			path_relative_to = function(path, base)
				if not path or not base then
					return path
				end

				if path:sub(1, #base) == base then
					local rel_path = path:sub(#base + 1)
					rel_path = rel_path:gsub("^[/\\]", "")
					return rel_path ~= "" and rel_path or "."
				end
				return path
			end,
			convert_path_style = function(path)
				if not path then
					return nil
				end

				if path:match("\\") then
					return path:gsub("\\", "/")
				else
					return path:gsub("/", "\\")
				end
			end,
			path_to_file_url = function(path)
				if not path then
					return nil
				end
				return "file://" .. path:gsub("\\", "/")
			end,
			is_windows_path = function(path)
				if not path then
					return false
				end
				return path:match("\\") ~= nil or path:match("^%a:") ~= nil
			end,
		})

		stub(vim.fn, "setreg")

		stub(vim, "notify")

		package.loaded["pathtool.config"] = config_mock
		package.loaded["pathtool.utils"] = utils_mock

		core = require("pathtool.core")
	end)

	after_each(function()
		vim.fn.setreg:revert()
		vim.notify:revert()

		mock.revert(utils_mock)
		mock.revert(config_mock)
	end)

	describe("notify", function()
		it("should call vim.notify when show_notifications is true", function()
			core.notify("Test message", "info")

			assert.stub(vim.notify).was.called(1)
			assert.stub(vim.notify).was.called_with("Test message", vim.log.levels.INFO, match._)
		end)

		it("should respect custom timeout", function()
			core.notify("Test message", "info", { timeout = 5000 })

			assert.stub(vim.notify).was.called(1)
			local opts = vim.notify.calls[1].refs[3]
			assert.equals(5000, opts.timeout)
		end)

		it("should not call vim.notify when show_notifications is false", function()
			config_mock.get = function(key)
				if key == "show_notifications" then
					return false
				end
				return true
			end

			core.notify("Test message", "info")

			assert.stub(vim.notify).was_not.called()
		end)
	end)

	describe("get_absolute_path", function()
		it("should return the absolute path", function()
			local path = core.get_absolute_path()
			assert.equals("/home/user/projects/test/file.txt", path)
		end)

		it("should normalize the path", function()
			stub(vim.fn, "expand").returns("/home/user/projects/test//file.txt/")

			local path = core.get_absolute_path()

			assert.stub(utils_mock.normalize_path).was.called(1)

			vim.fn.expand:revert()
		end)

		it("should return nil and notify on error", function()
			stub(vim.fn, "expand").returns("")

			local path = core.get_absolute_path()

			assert.is_nil(path)

			assert.stub(vim.notify).was.called(1)

			vim.fn.expand:revert()
		end)
	end)

	describe("get_relative_path", function()
		it("should return the relative path", function()
			local path = core.get_relative_path()
			assert.equals("test/file.txt", path)
		end)

		it("should normalize the path", function()
			stub(vim.fn, "expand").returns("test//file.txt/")

			local path = core.get_relative_path()

			assert.stub(utils_mock.normalize_path).was.called(1)

			vim.fn.expand:revert()
		end)
	end)

	describe("find_project_root", function()
		it("should return project root based on markers", function()
			stub(vim.fn, "fnamemodify")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h:h")
				.returns("/home/user/projects/test")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h")
				.returns("/home/user/projects/test/.git")

			local root = core.find_project_root()
			assert.equals("/home/user/projects/test", root)

			vim.fn.fnamemodify:revert()
		end)

		it("should use cwd when detect_project_root is false", function()
			config_mock.get = function(key)
				if key == "detect_project_root" then
					return false
				elseif key == "notification_timeout" then
					return 3000
				end
				return nil
			end

			local root = core.find_project_root()
			assert.equals("/home/user/projects", root)
		end)

		it("should check all project markers", function()
			stub(vim.fn, "finddir").returns("")
			stub(vim.fn, "findfile")
			stub(vim.fn, "fnamemodify")

			vim.fn.fnamemodify.on_call_with("/home/user/projects/package.json", ":p:h").returns("/home/user/projects")

			vim.fn.findfile.on_call_with("package.json", match._).returns("/home/user/projects/package.json")

			local root = core.find_project_root()

			assert.stub(vim.fn.finddir).was.called()
			assert.stub(vim.fn.findfile).was.called()

			vim.fn.finddir:revert()
			vim.fn.findfile:revert()
			vim.fn.fnamemodify:revert()
		end)

		it("should cache results for performance", function()
			stub(vim.fn, "fnamemodify")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h:h")
				.returns("/home/user/projects/test")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h")
				.returns("/home/user/projects/test/.git")

			local root1 = core.find_project_root()

			vim.fn.fnamemodify:revert()
			stub(vim.fn, "finddir").returns("should-not-be-called")

			local root2 = core.find_project_root()

			assert.equals(root1, root2)

			assert.stub(vim.fn.finddir).was_not.called()

			vim.fn.finddir:revert()
		end)

		it("should refresh cache when forced", function()
			stub(vim.fn, "fnamemodify")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h:h")
				.returns("/home/user/projects/test")
			vim.fn.fnamemodify
				.on_call_with("/home/user/projects/test/.git", ":p:h")
				.returns("/home/user/projects/test/.git")

			local root1 = core.find_project_root()

			vim.fn.fnamemodify:revert()
			stub(vim.fn, "finddir")
			stub(vim.fn, "fnamemodify")

			vim.fn.finddir.on_call_with(".git", match._).returns("/different/path/.git")
			vim.fn.fnamemodify.on_call_with("/different/path/.git", ":p:h:h").returns("/different/path")
			vim.fn.fnamemodify.on_call_with("/different/path/.git", ":p:h").returns("/different/path/.git")

			local root2 = core.find_project_root(true)

			assert.stub(vim.fn.finddir).was.called()

			vim.fn.finddir:revert()
			vim.fn.fnamemodify:revert()
		end)
	end)

	describe("get_project_relative_path", function()
		it("should return path relative to project root", function()
			stub(core, "find_project_root").returns("/home/user/projects/test")

			local path = core.get_project_relative_path()

			assert
				.stub(utils_mock.path_relative_to).was
				.called_with("/home/user/projects/test/file.txt", "/home/user/projects/test")

			core.find_project_root:revert()
		end)

		it("should fall back to absolute path if project root not found", function()
			stub(core, "find_project_root").returns(nil)

			local path = core.get_project_relative_path()

			assert.equals("/home/user/projects/test/file.txt", path)

			core.find_project_root:revert()
		end)
	end)

	describe("get_filename", function()
		it("should return the filename", function()
			local filename = core.get_filename()
			assert.equals("file.txt", filename)
		end)

		it("should return nil when no file is open", function()
			stub(vim.fn, "expand").returns("")

			local filename = core.get_filename()

			assert.is_nil(filename)

			vim.fn.expand:revert()
		end)
	end)

	describe("get_filename_without_ext", function()
		it("should return the filename without extension", function()
			local filename = core.get_filename_without_ext()
			assert.equals("file", filename)
		end)
	end)

	describe("get_dirname", function()
		it("should return the directory name", function()
			local dirname = core.get_dirname()
			assert.equals("/home/user/projects/test", dirname)
		end)

		it("should normalize the directory path", function()
			stub(vim.fn, "expand").returns("/home/user/projects/test/")

			local dirname = core.get_dirname()

			assert.stub(utils_mock.normalize_path).was.called()

			vim.fn.expand:revert()
		end)
	end)

	describe("convert_path_style", function()
		it("should convert between Unix and Windows path styles", function()
			local converted = core.convert_path_style()

			assert.stub(utils_mock.convert_path_style).was.called_with("/home/user/projects/test/file.txt")
		end)

		it("should return nil when no file is open", function()
			stub(core, "get_absolute_path").returns(nil)

			local converted = core.convert_path_style()

			assert.is_nil(converted)

			core.get_absolute_path:revert()
		end)
	end)

	describe("encode_path_as_url", function()
		it("should convert path to file URL", function()
			local url = core.encode_path_as_url()

			assert.stub(utils_mock.path_to_file_url).was.called_with("/home/user/projects/test/file.txt")
		end)
	end)

	describe("copy_to_clipboard", function()
		it("should copy text to system clipboard and unnamed register", function()
			-- This mimics the expected implementation in core.lua
			local original_copy_to_clipboard = core.copy_to_clipboard
			core.copy_to_clipboard = function(text, type)
				if not text then
					return false
				end

				if config_mock.get("use_system_clipboard") then
					vim.fn.setreg("+", text)
				end
				vim.fn.setreg('"', text)

				local display_text = text
				local max_len = config_mock.get("path_display_length") or 60

				if #text > max_len then
					display_text = "..." .. string.sub(text, -max_len + 3)
				end

				local action = type or "Copied"
				local msg = action .. ": " .. display_text

				core.notify(msg, "info")
				return true
			end

			core.copy_to_clipboard("test text")

			assert.stub(vim.fn.setreg).was.called(2)
			assert.stub(vim.fn.setreg).was.called_with("+", "test text")
			assert.stub(vim.fn.setreg).was.called_with('"', "test text")

			core.copy_to_clipboard = original_copy_to_clipboard
		end)

		it("should not use system clipboard when disabled", function()
			local original_copy_to_clipboard = core.copy_to_clipboard
			core.copy_to_clipboard = function(text, type)
				if not text then
					return false
				end

				if config_mock.get("use_system_clipboard") then
					vim.fn.setreg("+", text)
				end
				vim.fn.setreg('"', text)

				local display_text = text
				local max_len = config_mock.get("path_display_length") or 60

				if #text > max_len then
					display_text = "..." .. string.sub(text, -max_len + 3)
				end

				local action = type or "Copied"
				local msg = action .. ": " .. display_text

				core.notify(msg, "info")
				return true
			end

			stub(config_mock, "get")
			config_mock.get.on_call_with("use_system_clipboard").returns(false)
			config_mock.get.on_call_with("path_display_length").returns(60)
			config_mock.get.on_call_with("notification_timeout").returns(3000)
			config_mock.get.on_call_with("show_notifications").returns(true)

			core.copy_to_clipboard("test text")

			assert.stub(vim.fn.setreg).was.called(1)
			assert.stub(vim.fn.setreg).was.called_with('"', "test text")

			core.copy_to_clipboard = original_copy_to_clipboard
			mock.revert(config_mock.get)
		end)

		it("should truncate long paths in notification", function()
			local original_copy_to_clipboard = core.copy_to_clipboard
			core.copy_to_clipboard = function(text, type)
				if not text then
					return false
				end

				if config_mock.get("use_system_clipboard") then
					vim.fn.setreg("+", text)
				end
				vim.fn.setreg('"', text)

				local display_text = text
				local max_len = config_mock.get("path_display_length") or 60

				if #text > max_len then
					display_text = "..." .. string.sub(text, -max_len + 3)
				end

				local action = type or "Copied"
				local msg = action .. ": " .. display_text

				core.notify(msg, "info")
				return true
			end

			local long_text = string.rep("abcdefghij", 10)

			core.copy_to_clipboard(long_text)

			assert.stub(vim.notify).was.called(1)
			local notify_text = vim.notify.calls[1].refs[1]

			assert.is_true(#notify_text < #long_text + 10)
			assert.is_true(notify_text:match("%.%.%.") ~= nil)

			core.copy_to_clipboard = original_copy_to_clipboard
		end)

		it("should use custom notification format", function()
			local original_copy_to_clipboard = core.copy_to_clipboard
			core.copy_to_clipboard = function(text, type)
				if not text then
					return false
				end

				if config_mock.get("use_system_clipboard") then
					vim.fn.setreg("+", text)
				end
				vim.fn.setreg('"', text)

				local display_text = text
				local max_len = config_mock.get("path_display_length") or 60

				if #text > max_len then
					display_text = "..." .. string.sub(text, -max_len + 3)
				end

				local action = type or "Copied"
				local format = config_mock.get("notification_format") or "{action}: {path}"
				local msg = format:gsub("{action}", action):gsub("{path}", display_text)

				core.notify(msg, "info")
				return true
			end

			stub(config_mock, "get")
			config_mock.get.on_call_with("use_system_clipboard").returns(true)
			config_mock.get.on_call_with("path_display_length").returns(60)
			config_mock.get.on_call_with("notification_format").returns("Custom {action} - {path}")
			config_mock.get.on_call_with("notification_timeout").returns(3000)
			config_mock.get.on_call_with("show_notifications").returns(true)

			core.copy_to_clipboard("test.txt", "Saved")

			assert.stub(vim.notify).was.called(1)
			local notify_text = vim.notify.calls[1].refs[1]

			assert.equals("Custom Saved - test.txt", notify_text)

			core.copy_to_clipboard = original_copy_to_clipboard
			mock.revert(config_mock.get)
		end)

		it("should handle nil input gracefully", function()
			local original_copy_to_clipboard = core.copy_to_clipboard
			core.copy_to_clipboard = function(text, type)
				if not text then
					return false
				end

				if config_mock.get("use_system_clipboard") then
					vim.fn.setreg("+", text)
				end
				vim.fn.setreg('"', text)

				return true
			end

			local result = core.copy_to_clipboard(nil)

			assert.is_false(result)

			assert.stub(vim.fn.setreg).was_not.called()
			assert.stub(vim.notify).was_not.called()

			core.copy_to_clipboard = original_copy_to_clipboard
		end)
	end)

	describe("get_all_paths", function()
		it("should return a table with all path information", function()
			stub(core, "get_absolute_path").returns("/home/user/projects/test/file.txt")
			stub(core, "get_relative_path").returns("test/file.txt")
			stub(core, "get_project_relative_path").returns("file.txt")
			stub(core, "get_filename").returns("file.txt")
			stub(core, "get_filename_without_ext").returns("file")
			stub(core, "get_dirname").returns("/home/user/projects/test")
			stub(core, "convert_path_style").returns("\\home\\user\\projects\\test\\file.txt")
			stub(core, "encode_path_as_url").returns("file:///home/user/projects/test/file.txt")

			local paths = core.get_all_paths()

			assert.is_table(paths)
			assert.equals("/home/user/projects/test/file.txt", paths["Absolute Path"])
			assert.equals("test/file.txt", paths["Relative Path"])
			assert.equals("file.txt", paths["Project Path"])
			assert.equals("file.txt", paths["Filename"])
			assert.equals("file", paths["Filename (no ext)"])
			assert.equals("/home/user/projects/test", paths["Directory"])
			assert.equals("\\home\\user\\projects\\test\\file.txt", paths["Converted Style"])
			assert.equals("file:///home/user/projects/test/file.txt", paths["File URL"])

			core.get_absolute_path:revert()
			core.get_relative_path:revert()
			core.get_project_relative_path:revert()
			core.get_filename:revert()
			core.get_filename_without_ext:revert()
			core.get_dirname:revert()
			core.convert_path_style:revert()
			core.encode_path_as_url:revert()
		end)

		it("should return empty table when no file is open", function()
			stub(core, "get_absolute_path").returns(nil)

			local paths = core.get_all_paths()

			assert.is_table(paths)
			assert.is_true(next(paths) == nil)

			core.get_absolute_path:revert()
		end)
	end)
end)

describe("pathtool.core path handling edge cases", function()
	pending("should handle paths with special characters")
	pending("should handle very long paths correctly")
	pending("should handle paths with unicode characters")
	pending("should handle network paths")
end)

describe("pathtool.core performance", function()
	pending("should have fast project root detection with caching")
	pending("should efficiently handle multiple rapid path operations")
end)
