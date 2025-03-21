local mock = require("ert.mock")
local stub = require("luassert.stub")

_G.vim = {
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
	getcwd = function()
		return "/home/user/projects"
	end,
	fnamemodify = function(path, modifier)
		if not path then
			return nil
		end

		if modifier == ":p:h" then
			return path:match("(.+)/[^/]+$") or path
		elseif modifier == ":h" then
			return path:match("(.+)/[^/]+$") or path
		elseif modifier == ":r" then
			return path:match("(.+)%.[^.]+$") or path
		end
		return path
	end,
}

describe("pathtool.utils", function()
	local utils

	before_each(function()
		package.loaded["pathtool.utils"] = nil
		utils = require("pathtool.utils")
	end)

	describe("is_windows", function()
		it("should detect Windows OS correctly", function()
			stub(vim.fn, "has")

			vim.fn.has.on_call_with("win32").returns(1)
			vim.fn.has.on_call_with("win64").returns(1)
			assert.is_true(utils.is_windows())

			vim.fn.has:revert()
		end)
	end)

	describe("is_unix", function()
		it("should detect Unix OS correctly", function()
			stub(vim.fn, "has")

			vim.fn.has.on_call_with("win32").returns(0)
			vim.fn.has.on_call_with("win64").returns(0)
			vim.fn.has.on_call_with("unix").returns(1)
			assert.is_true(utils.is_unix())

			vim.fn.has:revert()
		end)
	end)

	describe("is_macos", function()
		it("should detect macOS correctly", function()
			stub(vim.fn, "has")

			vim.fn.has.on_call_with("mac").returns(1)
			vim.fn.has.on_call_with("macunix").returns(1)
			assert.is_true(utils.is_macos())

			vim.fn.has:revert()
		end)
	end)

	describe("is_windows_path", function()
		it("should detect Windows paths", function()
			local windows_paths = {
				"C:\\Users\\test\\file.txt",
				"D:\\Program Files\\App\\data.csv",
				"C:file.txt",
				"file\\path\\test.lua",
			}

			for _, path in ipairs(windows_paths) do
				assert.is_true(utils.is_windows_path(path), "Path should be detected as Windows: " .. path)
			end
		end)

		it("should handle edge cases", function()
			assert.is_false(utils.is_windows_path(nil))
			assert.is_false(utils.is_windows_path(""))
		end)
	end)

	describe("is_unix_path", function()
		it("should detect Unix paths", function()
			local unix_paths = {
				"/home/user/file.txt",
				"./relative/path.txt",
				"../parent/file.txt",
				"/usr/local/bin",
			}

			for _, path in ipairs(unix_paths) do
				assert.is_true(utils.is_unix_path(path), "Path should be detected as Unix: " .. path)
			end
		end)

		it("should handle edge cases", function()
			assert.is_false(utils.is_unix_path(nil))
			assert.is_false(utils.is_unix_path(""))
			assert.is_false(utils.is_unix_path("C:\\test\\file.txt"))
		end)
	end)

	describe("to_native_path", function()
		it("should convert paths to native format on Windows", function()
			stub(utils, "is_windows").returns(true)

			assert.equals("C:\\Users\\test\\file.txt", utils.to_native_path("/c/Users/test/file.txt"))
			assert.equals("file\\path\\test.lua", utils.to_native_path("file/path/test.lua"))

			utils.is_windows:revert()
		end)

		it("should convert paths to native format on Unix", function()
			stub(utils, "is_windows").returns(false)

			assert.equals("/c/Users/test/file.txt", utils.to_native_path("C:\\Users\\test\\file.txt"))
			assert.equals("file/path/test.lua", utils.to_native_path("file\\path\\test.lua"))

			utils.is_windows:revert()
		end)

		it("should return unchanged path when already in native format", function()
			stub(utils, "is_windows").returns(true)
			stub(utils, "is_unix_path").returns(false)

			local path = "C:\\Users\\test\\file.txt"
			assert.equals(path, utils.to_native_path(path))

			utils.is_windows:revert()
			utils.is_unix_path:revert()
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.to_native_path(nil))
		end)
	end)

	describe("convert_path_style", function()
		it("should convert Windows paths to Unix", function()
			local windows_path = "C:\\Users\\test\\file.txt"
			local unix_path = "/c/Users/test/file.txt"

			stub(utils, "is_windows_path").returns(true)

			assert.equals(unix_path, utils.convert_path_style(windows_path))

			utils.is_windows_path:revert()
		end)

		it("should convert Unix paths to Windows", function()
			local unix_path = "/home/user/file.txt"
			local windows_path = "C:\\home\\user\\file.txt"

			stub(utils, "is_windows_path").returns(false)
			stub(vim.fn, "getcwd").returns("C:\\Users\\test")

			assert.equals(windows_path:gsub("C:", "C:"), utils.convert_path_style(unix_path))

			utils.is_windows_path:revert()
			vim.fn.getcwd:revert()
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.convert_path_style(nil))
		end)
	end)

	describe("normalize_path", function()
		it("should remove trailing slashes", function()
			assert.equals("/home/user/file", utils.normalize_path("/home/user/file/"))
			assert.equals("C:\\Users\\test", utils.normalize_path("C:\\Users\\test\\"))
		end)

		it("should collapse multiple slashes", function()
			assert.equals("/home/user/file", utils.normalize_path("/home//user///file"))
			assert.equals("C:\\Users\\test", utils.normalize_path("C:\\\\Users\\\\\\test"))
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.normalize_path(nil))
		end)
	end)

	describe("url_encode", function()
		it("should encode special characters", function()
			assert.equals("hello%20world", utils.url_encode("hello world"))
			assert.equals("file%3Fwith%26special%23chars", utils.url_encode("file?with&special#chars"))
		end)

		it("should not encode alphanumeric and safe characters", function()
			assert.equals("abcDEF123-._~", utils.url_encode("abcDEF123-._~"))
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.url_encode(nil))
		end)
	end)

	describe("path_to_file_url", function()
		it("should convert Unix paths to file URLs", function()
			assert.equals("file:///home/user/file.txt", utils.path_to_file_url("/home/user/file.txt"))
		end)

		it("should convert Windows paths to file URLs", function()
			stub(utils, "is_windows_path").returns(true)
			stub(utils, "normalize_path").returns("C:\\Users\\test\\file.txt")

			assert.equals("file:///C:/Users/test/file.txt", utils.path_to_file_url("C:\\Users\\test\\file.txt"))

			utils.is_windows_path:revert()
			utils.normalize_path:revert()
		end)

		it("should encode special characters in the path", function()
			stub(utils, "url_encode").returns("encoded%20segment")

			local result = utils.path_to_file_url("/path/with space/file.txt")
			assert.is_true(result:find("encoded%%20segment") ~= nil)

			utils.url_encode:revert()
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.path_to_file_url(nil))
		end)
	end)

	describe("path_relative_to", function()
		it("should return relative path when under base", function()
			assert.equals("subdir/file.txt", utils.path_relative_to("/home/user/subdir/file.txt", "/home/user"))
			assert.equals(
				"subdir\\file.txt",
				utils.path_relative_to("C:\\Users\\test\\subdir\\file.txt", "C:\\Users\\test")
			)
		end)

		it("should return original path when not under base", function()
			assert.equals("/other/path/file.txt", utils.path_relative_to("/other/path/file.txt", "/home/user"))
		end)

		it("should return '.' when path equals base", function()
			assert.equals(".", utils.path_relative_to("/home/user", "/home/user"))
		end)

		it("should normalize paths before comparison", function()
			stub(utils, "normalize_path")
			utils.normalize_path.on_call_with("/home/user/file.txt").returns("/home/user/file.txt")
			utils.normalize_path.on_call_with("/home/user/").returns("/home/user")

			utils.path_relative_to("/home/user/file.txt", "/home/user/")

			assert.stub(utils.normalize_path).was.called(2)

			utils.normalize_path:revert()
		end)

		it("should handle nil inputs gracefully", function()
			assert.is_nil(utils.path_relative_to(nil, "/base"))
			assert.equals("/path", utils.path_relative_to("/path", nil))
		end)
	end)

	describe("change_extension", function()
		it("should change file extension", function()
			assert.equals("file.js", utils.change_extension("file.txt", "js"))
			assert.equals("path/to/file.html", utils.change_extension("path/to/file.txt", "html"))
		end)

		it("should add extension to files without one", function()
			assert.equals("file.js", utils.change_extension("file", "js"))
		end)

		it("should support extensions with leading dot", function()
			assert.equals("file.js", utils.change_extension("file.txt", ".js"))
		end)

		it("should remove extension when nil is passed", function()
			assert.equals("file", utils.change_extension("file.txt", nil))
		end)

		it("should handle nil path gracefully", function()
			assert.is_nil(utils.change_extension(nil, "js"))
		end)
	end)

	describe("path_up", function()
		it("should return parent directory", function()
			stub(vim.fn, "fnamemodify")
			vim.fn.fnamemodify.on_call_with("/home/user/file.txt", ":h").returns("/home/user")

			assert.equals("/home/user", utils.path_up("/home/user/file.txt"))

			vim.fn.fnamemodify:revert()
		end)

		it("should go up multiple levels when specified", function()
			stub(vim.fn, "fnamemodify")
			vim.fn.fnamemodify.on_call_with("/home/user/subdir/file.txt", ":h").returns("/home/user/subdir")
			vim.fn.fnamemodify.on_call_with("/home/user/subdir", ":h").returns("/home/user")

			assert.equals("/home/user", utils.path_up("/home/user/subdir/file.txt", 2))

			vim.fn.fnamemodify:revert()
		end)

		it("should handle nil path gracefully", function()
			assert.is_nil(utils.path_up(nil))
		end)
	end)

	describe("join_paths", function()
		it("should join paths with correct separator", function()
			stub(utils, "is_windows_path").returns(false)
			stub(utils, "normalize_path").returns(function(p)
				return p
			end)

			assert.equals("/home/user/file.txt", utils.join_paths("/home/user", "file.txt"))

			utils.is_windows_path:revert()
			utils.normalize_path:revert()

			stub(utils, "is_windows_path").returns(true)

			assert.equals("C:\\Users\\test\\file.txt", utils.join_paths("C:\\Users\\test", "file.txt"))

			utils.is_windows_path:revert()
		end)

		it("should handle absolute second path", function()
			assert.equals("/absolute/path", utils.join_paths("/home/user", "/absolute/path"))
			assert.equals("C:\\absolute\\path", utils.join_paths("D:\\Users\\test", "C:\\absolute\\path"))
		end)

		it("should handle paths with and without trailing separators", function()
			assert.equals("/home/user/file.txt", utils.join_paths("/home/user/", "file.txt"))
		end)

		it("should handle nil inputs gracefully", function()
			assert.is_nil(utils.join_paths(nil, nil))
			assert.equals("/path", utils.join_paths("/path", nil))
			assert.equals("/path", utils.join_paths(nil, "/path"))
		end)
	end)

	describe("safe_display_path", function()
		it("should return short paths unchanged", function()
			assert.equals("short/path.txt", utils.safe_display_path("short/path.txt", 60))
		end)

		it("should truncate long paths", function()
			local long_path = "/very/long/path/with/many/subdirectories/and/a/filename.txt"
			local truncated = utils.safe_display_path(long_path, 20)

			assert.is_true(#truncated <= 20)
			assert.is_true(truncated:find("%.%.%.") ~= nil)
		end)

		it("should preserve filename in truncated paths", function()
			stub(utils, "is_windows_path").returns(false)

			local long_path = "/very/long/path/with/many/subdirectories/and/a/filename.txt"
			local truncated = utils.safe_display_path(long_path, 30)

			assert.is_true(truncated:find("filename.txt") ~= nil)

			utils.is_windows_path:revert()
		end)

		it("should handle different path styles", function()
			stub(utils, "is_windows_path").returns(true)

			local windows_path = "C:\\very\\long\\path\\with\\many\\subdirectories\\and\\a\\filename.txt"
			local truncated = utils.safe_display_path(windows_path, 30)

			assert.is_true(truncated:find("filename.txt") ~= nil)

			utils.is_windows_path:revert()
		end)

		it("should handle nil inputs gracefully", function()
			assert.is_nil(utils.safe_display_path(nil))
		end)
	end)
end)
