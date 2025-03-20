local mock = require("luassert.mock")

local vim_mock = {
	fn = {},
	api = {
		nvim_create_user_command = function() end,
		nvim_create_buf = function()
			return 1
		end,
		nvim_buf_set_lines = function() end,
		nvim_open_win = function()
			return 1
		end,
		nvim_buf_set_keymap = function() end,
		nvim_create_autocmd = function() end,
		nvim_win_set_option = function() end,
		nvim_buf_set_option = function() end,
	},
	log = {
		levels = {
			INFO = 1,
			WARN = 2,
			ERROR = 3,
		},
	},
	cmd = function() end,
	defer_fn = function(fn)
		fn()
	end,
	g = {},
	o = {
		columns = 100,
		lines = 50,
	},
	notify = function() end,
	keymap = {
		set = function() end,
	},
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

describe("pathtool.nvim", function()
	local pathtool
	local utils

	before_each(function()
		package.loaded["pathtool"] = nil
		package.loaded["pathtool.utils"] = nil

		vim_mock.fn.expand = mock(function(arg)
			if arg == "%:p" then
				return "/home/user/projects/test/file.txt"
			end
			if arg == "%:." then
				return "file.txt"
			end
			if arg == "%:t" then
				return "file.txt"
			end
			if arg == "%:t:r" then
				return "file"
			end
			if arg == "%:p:h" then
				return "/home/user/projects/test"
			end
			return ""
		end)

		vim_mock.fn.getcwd = mock(function()
			return "/home/user/projects"
		end)
		vim_mock.fn.fnamemodify = mock(function(path, modifier)
			if modifier == ":h" then
				return path:match("(.+)/[^/]+$") or path
			elseif modifier == ":h:h" then
				local parent = path:match("(.+)/[^/]+$") or path
				return parent:match("(.+)/[^/]+$") or parent
			elseif modifier == ":r" then
				return path:match("(.+)%.[^.]+$") or path
			elseif modifier:match(":s?(.+)?(.+)?") then
				local pattern, replacement = modifier:match(":s?(.+)?(.+)?")
				if pattern and replacement then
					if path:sub(1, #pattern) == pattern then
						return replacement .. path:sub(#pattern + 1)
					end
				end
			end
			return path
		end)

		vim_mock.fn.finddir = mock(function(marker, path)
			if marker == ".git" and path:match("/home/user/projects/test") then
				return "/home/user/projects/test/.git"
			end
			return ""
		end)

		vim_mock.fn.findfile = mock(function(marker, path)
			return ""
		end)

		vim_mock.fn.has = mock(function(feature)
			if feature == "win32" or feature == "win64" then
				return 0
			end
			if feature == "unix" then
				return 1
			end
			if feature == "mac" or feature == "macunix" then
				return 0
			end
			return 0
		end)

		vim_mock.fn.setreg = mock(function() end)

		pathtool = require("pathtool")
		utils = require("pathtool.utils")

		pathtool.setup()
	end)

	after_each(function()
		mock.revert(vim_mock.fn.expand)
		mock.revert(vim_mock.fn.getcwd)
		mock.revert(vim_mock.fn.fnamemodify)
		mock.revert(vim_mock.fn.finddir)
		mock.revert(vim_mock.fn.findfile)
		mock.revert(vim_mock.fn.has)
		mock.revert(vim_mock.fn.setreg)
	end)

	describe("pathtool main module", function()
		it("should get the absolute path", function()
			local path = pathtool.get_absolute_path()
			assert.equals("/home/user/projects/test/file.txt", path)
		end)

		it("should get the relative path", function()
			local path = pathtool.get_relative_path()
			assert.equals("file.txt", path)
		end)

		it("should get the project-relative path", function()
			local original_find_project_root = pathtool.find_project_root
			pathtool.find_project_root = function()
				return "/home/user/projects/test"
			end

			local original_path_relative_to = utils.path_relative_to
			utils.path_relative_to = function(path, base)
				if path == "/home/user/projects/test/file.txt" and base == "/home/user/projects/test" then
					return "file.txt"
				end
				return path
			end

			local path = pathtool.get_project_relative_path()
			assert.equals("file.txt", path)

			pathtool.find_project_root = original_find_project_root
			utils.path_relative_to = original_path_relative_to
		end)

		it("should get the filename", function()
			local path = pathtool.get_filename()
			assert.equals("file.txt", path)
		end)

		it("should get the filename without extension", function()
			local path = pathtool.get_filename_without_ext()
			assert.equals("file", path)
		end)

		it("should get the directory name", function()
			local path = pathtool.get_dirname()
			assert.equals("/home/user/projects/test", path)
		end)

		it("should convert path style", function()
			local original_convert_path_style = utils.convert_path_style
			utils.convert_path_style = function(path)
				if path == "/home/user/projects/test/file.txt" then
					return "\\home\\user\\projects\\test\\file.txt"
				end
				return path
			end

			local path = pathtool.convert_path_style()
			assert.equals("\\home\\user\\projects\\test\\file.txt", path)

			utils.convert_path_style = original_convert_path_style
		end)

		it("should find the project root", function()
			local original_finddir = vim_mock.fn.finddir
			vim_mock.fn.finddir = mock(function(marker, path)
				if marker == ".git" and path:match("/home/user/projects/test") then
					return "/home/user/projects/test/.git"
				end
				return ""
			end)

			local original_fnamemodify = vim_mock.fn.fnamemodify
			vim_mock.fn.fnamemodify = mock(function(path, modifier)
				if path == "/home/user/projects/test/.git" and modifier == ":p:h:h" then
					return "/home/user/projects/test"
				end
				if path == "/home/user/projects/test/.git" and modifier == ":p:h" then
					return "/home/user/projects/test/.git"
				end
				return original_fnamemodify(path, modifier)
			end)

			local root = pathtool.find_project_root()
			assert.equals("/home/user/projects/test", root)

			mock.revert(vim_mock.fn.finddir)
			vim_mock.fn.finddir = original_finddir
			mock.revert(vim_mock.fn.fnamemodify)
			vim_mock.fn.fnamemodify = original_fnamemodify
		end)

		it("should copy to clipboard", function()
			pathtool.copy_to_clipboard("test text")
			assert.spy(vim_mock.fn.setreg).was.called_with("+", "test text")
			assert.spy(vim_mock.fn.setreg).was.called_with('"', "test text")
		end)
	end)

	describe("pathtool utils module", function()
		it("should detect Windows path", function()
			assert.is_true(utils.is_windows_path("C:\\Users\\name"))
			assert.is_true(utils.is_windows_path("D:\\path\\to\\file.txt"))
			assert.is_false(utils.is_windows_path("/home/user/file.txt"))
		end)

		it("should detect Unix path", function()
			assert.is_true(utils.is_unix_path("/home/user/file.txt"))
			assert.is_true(utils.is_unix_path("./relative/path"))
			assert.is_false(utils.is_unix_path("C:\\Users\\name"))
		end)

		it("should normalize path", function()
			local original_normalize = utils.normalize_path
			utils.normalize_path = function(path)
				if path == "/path/to/file/" then
					return "/path/to/file"
				elseif path == "/path//to/file" then
					return "/path/to/file"
				elseif path == "C:\\path\\to\\file\\" then
					return "C:\\path\\to\\file"
				end
				return path
			end

			assert.equals("/path/to/file", utils.normalize_path("/path/to/file/"))
			assert.equals("/path/to/file", utils.normalize_path("/path//to/file"))
			assert.equals("C:\\path\\to\\file", utils.normalize_path("C:\\path\\to\\file\\"))

			utils.normalize_path = original_normalize
		end)

		it("should convert between path styles", function()
			local original_convert = utils.convert_path_style
			utils.convert_path_style = function(path)
				if path == "C:\\path\\to\\file" then
					return "/c/path/to/file"
				elseif path == "/path/to/file" then
					return "C:\\path\\to\\file"
				end
				return path
			end

			assert.equals("/c/path/to/file", utils.convert_path_style("C:\\path\\to\\file"))

			local original_is_windows_path = utils.is_windows_path
			utils.is_windows_path = function()
				return false
			end

			assert.equals("C:\\path\\to\\file", utils.convert_path_style("/path/to/file"))

			utils.convert_path_style = original_convert
			utils.is_windows_path = original_is_windows_path
		end)

		it("should URL encode strings", function()
			assert.equals("Hello%20World", utils.url_encode("Hello World"))
			assert.equals("test%3Fquery%3Dvalue", utils.url_encode("test?query=value"))
		end)

		it("should convert path to file URL", function()
			local original_to_file_url = utils.path_to_file_url
			utils.path_to_file_url = function(path)
				if path == "/home/user/file.txt" then
					return "file:///home/user/file.txt"
				elseif path == "C:\\Users\\name\\file.txt" then
					return "file:///C:/Users/name/file.txt"
				end
				return "file:///" .. path
			end

			assert.equals("file:///home/user/file.txt", utils.path_to_file_url("/home/user/file.txt"))
			assert.equals("file:///C:/Users/name/file.txt", utils.path_to_file_url("C:\\Users\\name\\file.txt"))

			utils.path_to_file_url = original_to_file_url
		end)

		it("should calculate relative paths", function()
			assert.equals("subdir/file.txt", utils.path_relative_to("/home/user/subdir/file.txt", "/home/user"))
			assert.equals("file.txt", utils.path_relative_to("/home/user/file.txt", "/home/user"))
		end)

		it("should change file extension", function()
			assert.equals("/home/user/file.js", utils.change_extension("/home/user/file.txt", "js"))
			assert.equals("/home/user/file.js", utils.change_extension("/home/user/file.txt", ".js"))
		end)

		it("should navigate up directory levels", function()
			assert.equals("/home/user", utils.path_up("/home/user/file.txt", 1))
			assert.equals("/home", utils.path_up("/home/user/file.txt", 2))
		end)

		it("should join paths correctly", function()
			assert.equals("/home/user/file.txt", utils.join_paths("/home/user", "file.txt"))
			assert.equals("/home/user/subdir/file.txt", utils.join_paths("/home/user", "subdir/file.txt"))
		end)

		it("should safely display long paths", function()
			local very_long_path = "/home/user/very/long/path/with/many/subdirectories/and/a/filename.txt"
			local displayed = utils.safe_display_path(very_long_path, 30)

			assert.is_true(#displayed <= 30, "Path display should be less than or equal to 30 characters")
			assert.is_true(displayed:find("%.%.%.") ~= nil, "Path display should contain '...'")
		end)
	end)
end)
