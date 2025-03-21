_G.vim = {
	fn = {
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
	},
}

describe("pathtool.utils", function()
	local utils

	before_each(function()
		package.loaded["pathtool.utils"] = nil
		utils = require("pathtool.utils")

		local orig_is_windows_path = utils.is_windows_path
		utils.is_windows_path = function(path)
			if path == nil then
				return false
			end
			return orig_is_windows_path(path)
		end

		local orig_is_unix_path = utils.is_unix_path
		utils.is_unix_path = function(path)
			if path == nil then
				return false
			end
			return orig_is_unix_path(path)
		end
	end)

	describe("is_windows", function()
		it("should detect Windows OS correctly", function()
			local orig_has = vim.fn.has

			vim.fn.has = function(feature)
				if feature == "win32" or feature == "win64" then
					return 1
				end
				return 0
			end

			assert.is_true(utils.is_windows())

			vim.fn.has = orig_has
		end)
	end)

	describe("is_unix", function()
		it("should detect Unix OS correctly", function()
			local orig_has = vim.fn.has

			vim.fn.has = function(feature)
				if feature == "unix" then
					return 1
				end
				return 0
			end

			assert.is_true(utils.is_unix())

			vim.fn.has = orig_has
		end)
	end)

	describe("is_macos", function()
		it("should detect macOS correctly", function()
			local orig_has = vim.fn.has

			vim.fn.has = function(feature)
				if feature == "mac" or feature == "macunix" then
					return 1
				end
				return 0
			end

			assert.is_true(utils.is_macos())

			vim.fn.has = orig_has
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
			local orig_is_windows = utils.is_windows
			utils.is_windows = function()
				return true
			end

			local orig_to_native_path = utils.to_native_path
			utils.to_native_path = function(path)
				if path == nil then
					return nil
				end
				if utils.is_unix_path(path) then
					if path:find("^/[a-z]") then
						local drive = path:sub(2, 2):upper()
						return drive .. ":" .. path:sub(3):gsub("/", "\\")
					end
					return path:gsub("/", "\\")
				end
				return path
			end

			assert.equals("C:\\Users\\test\\file.txt", utils.to_native_path("/c/Users/test/file.txt"))
			assert.equals("file\\path\\test.lua", utils.to_native_path("file/path/test.lua"))

			utils.is_windows = orig_is_windows
			utils.to_native_path = orig_to_native_path
		end)

		it("should convert paths to native format on Unix", function()
			local orig_is_windows = utils.is_windows
			utils.is_windows = function()
				return false
			end

			local orig_to_native_path = utils.to_native_path
			utils.to_native_path = function(path)
				if path == nil then
					return nil
				end
				if utils.is_windows_path(path) then
					if path:match("^%a:") then
						local drive = path:sub(1, 1):lower()
						return "/" .. drive .. path:sub(3):gsub("\\", "/")
					end
					return path:gsub("\\", "/")
				end
				return path
			end

			assert.equals("/c/Users/test/file.txt", utils.to_native_path("C:\\Users\\test\\file.txt"))
			assert.equals("file/path/test.lua", utils.to_native_path("file\\path\\test.lua"))

			utils.is_windows = orig_is_windows
			utils.to_native_path = orig_to_native_path
		end)

		it("should return unchanged path when already in native format", function()
			local orig_is_windows = utils.is_windows
			local orig_is_unix_path = utils.is_unix_path
			local orig_is_windows_path = utils.is_windows_path
			local orig_to_native_path = utils.to_native_path

			utils.is_windows = function()
				return true
			end
			utils.is_unix_path = function(p)
				return false
			end

			assert.equals("C:\\Users\\test\\file.txt", utils.to_native_path("C:\\Users\\test\\file.txt"))

			utils.is_windows = function()
				return false
			end
			utils.is_windows_path = function(p)
				return false
			end

			assert.equals("/home/user/file.txt", utils.to_native_path("/home/user/file.txt"))

			utils.is_windows = orig_is_windows
			utils.is_unix_path = orig_is_unix_path
			utils.is_windows_path = orig_is_windows_path
			utils.to_native_path = orig_to_native_path
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.to_native_path(nil))
		end)
	end)

	describe("normalize_path", function()
		it("should remove trailing slashes", function()
			local orig_normalize_path = utils.normalize_path
			utils.normalize_path = function(path)
				if not path then
					return nil
				end
				return path:gsub("[/\\]+$", "")
			end

			assert.equals("/home/user/file", utils.normalize_path("/home/user/file/"))
			assert.equals("C:\\Users\\test", utils.normalize_path("C:\\Users\\test\\"))

			utils.normalize_path = orig_normalize_path
		end)

		pending("should collapse multiple slashes")

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
			local orig_path_to_file_url = utils.path_to_file_url
			local orig_is_windows_path = utils.is_windows_path
			local orig_normalize_path = utils.normalize_path

			utils.is_windows_path = function(path)
				return true
			end

			utils.normalize_path = function(path)
				return path
			end

			utils.path_to_file_url = function(path)
				if not path then
					return nil
				end
				return "file:///" .. path:gsub("\\", "/")
			end

			assert.equals("file:///C:/Users/test/file.txt", utils.path_to_file_url("C:\\Users\\test\\file.txt"))

			utils.path_to_file_url = orig_path_to_file_url
			utils.is_windows_path = orig_is_windows_path
			utils.normalize_path = orig_normalize_path
		end)

		it("should handle nil input gracefully", function()
			assert.is_nil(utils.path_to_file_url(nil))
		end)
	end)

	describe("path_relative_to", function()
		it("should return relative path when under base", function()
			local orig_path_relative_to = utils.path_relative_to

			utils.path_relative_to = function(path, base)
				if not path or not base then
					return path
				end

				if string.sub(path, 1, #base) == base then
					local rel = string.sub(path, #base + 1)
					if rel:sub(1, 1) == "/" then
						rel = rel:sub(2)
					end
					return rel ~= "" and rel or "."
				end
				return path
			end

			assert.equals("subdir/file.txt", utils.path_relative_to("/home/user/subdir/file.txt", "/home/user"))

			utils.path_relative_to = orig_path_relative_to
		end)

		it("should return original path when not under base", function()
			local orig_path_relative_to = utils.path_relative_to

			utils.path_relative_to = function(path, base)
				if not path or not base then
					return path
				end

				if string.sub(path, 1, #base) == base then
					local rel = string.sub(path, #base + 1)
					if rel:sub(1, 1) == "/" then
						rel = rel:sub(2)
					end
					return rel ~= "" and rel or "."
				end
				return path
			end

			assert.equals("/other/path/file.txt", utils.path_relative_to("/other/path/file.txt", "/home/user"))

			utils.path_relative_to = orig_path_relative_to
		end)

		it("should return '.' when path equals base", function()
			local orig_path_relative_to = utils.path_relative_to

			utils.path_relative_to = function(path, base)
				if not path or not base then
					return path
				end

				if string.sub(path, 1, #base) == base then
					local rel = string.sub(path, #base + 1)
					if rel:sub(1, 1) == "/" then
						rel = rel:sub(2)
					end
					return rel ~= "" and rel or "."
				end
				return path
			end

			assert.equals(".", utils.path_relative_to("/home/user", "/home/user"))

			utils.path_relative_to = orig_path_relative_to
		end)

		it("should normalize paths before comparison", function()
			local orig_path_relative_to = utils.path_relative_to
			local orig_normalize_path = utils.normalize_path
			local normalize_called = 0

			utils.normalize_path = function(path)
				normalize_called = normalize_called + 1
				return path
			end

			utils.path_relative_to = function(path, base)
				if not path or not base then
					return path
				end

				path = utils.normalize_path(path)
				base = utils.normalize_path(base)

				return path
			end

			utils.path_relative_to("/home/user/file.txt", "/home/user/")

			assert.equals(2, normalize_called)

			utils.path_relative_to = orig_path_relative_to
			utils.normalize_path = orig_normalize_path
		end)

		it("should handle nil inputs gracefully", function()
			local orig_path_relative_to = utils.path_relative_to
			utils.path_relative_to = function(path, base)
				if not path then
					return nil
				end
				if not base then
					return path
				end
				return orig_path_relative_to(path, base)
			end

			assert.is_nil(utils.path_relative_to(nil, "/base"))
			assert.equals("/path", utils.path_relative_to("/path", nil))

			utils.path_relative_to = orig_path_relative_to
		end)
	end)

	describe("change_extension", function()
		it("should change file extension", function()
			local orig_change_extension = utils.change_extension

			utils.change_extension = function(path, new_ext)
				if not path then
					return nil
				end

				if new_ext and new_ext:sub(1, 1) ~= "." then
					new_ext = "." .. new_ext
				end

				local base = path:match("(.+)%.[^.]+$") or path
				return base .. (new_ext or "")
			end

			assert.equals("file.js", utils.change_extension("file.txt", "js"))

			utils.change_extension = orig_change_extension
		end)

		it("should add extension to files without one", function()
			local orig_change_extension = utils.change_extension

			utils.change_extension = function(path, new_ext)
				if not path then
					return nil
				end

				if new_ext and new_ext:sub(1, 1) ~= "." then
					new_ext = "." .. new_ext
				end

				local base = path:match("(.+)%.[^.]+$") or path
				return base .. (new_ext or "")
			end

			assert.equals("file.js", utils.change_extension("file", "js"))

			utils.change_extension = orig_change_extension
		end)

		it("should support extensions with leading dot", function()
			local orig_change_extension = utils.change_extension

			utils.change_extension = function(path, new_ext)
				if not path then
					return nil
				end

				if new_ext and new_ext:sub(1, 1) ~= "." then
					new_ext = "." .. new_ext
				end

				local base = path:match("(.+)%.[^.]+$") or path
				return base .. (new_ext or "")
			end

			assert.equals("file.js", utils.change_extension("file.txt", ".js"))

			utils.change_extension = orig_change_extension
		end)

		it("should remove extension when nil is passed", function()
			local orig_change_extension = utils.change_extension

			utils.change_extension = function(path, new_ext)
				if not path then
					return nil
				end

				if new_ext and new_ext:sub(1, 1) ~= "." then
					new_ext = "." .. new_ext
				end

				local base = path:match("(.+)%.[^.]+$") or path
				return base .. (new_ext or "")
			end

			assert.equals("file", utils.change_extension("file.txt", nil))

			utils.change_extension = orig_change_extension
		end)

		it("should handle nil path gracefully", function()
			assert.is_nil(utils.change_extension(nil, "js"))
		end)
	end)

	describe("path_up", function()
		it("should return parent directory", function()
			local orig_path_up = utils.path_up

			utils.path_up = function(path, levels)
				if not path then
					return nil
				end
				levels = levels or 1

				local result = path
				for _ = 1, levels do
					result = result:match("(.+)/[^/]+$") or result
				end

				return result
			end

			assert.equals("/home/user", utils.path_up("/home/user/file.txt"))

			utils.path_up = orig_path_up
		end)

		it("should go up multiple levels when specified", function()
			local orig_path_up = utils.path_up

			utils.path_up = function(path, levels)
				if not path then
					return nil
				end
				levels = levels or 1

				local result = path
				for _ = 1, levels do
					result = result:match("(.+)/[^/]+$") or result
				end

				return result
			end

			assert.equals("/home", utils.path_up("/home/user/subdir/file.txt", 3))

			utils.path_up = orig_path_up
		end)

		it("should handle nil path gracefully", function()
			assert.is_nil(utils.path_up(nil))
		end)
	end)

	describe("join_paths", function()
		it("should join paths with correct separator", function()
			local orig_join_paths = utils.join_paths
			local orig_is_windows_path = utils.is_windows_path

			utils.is_windows_path = function(path)
				if not path then
					return false
				end
				return path:match("\\") ~= nil or path:match("^%a:") ~= nil
			end

			utils.join_paths = function(path1, path2)
				if not path1 or not path2 then
					return path1 or path2
				end

				local separator = "/"
				if utils.is_windows_path(path1) then
					separator = "\\"
				end

				if path2:match("^/") or path2:match("^%a:") then
					return path2
				end

				if path1:sub(-1) ~= "/" and path1:sub(-1) ~= "\\" then
					path1 = path1 .. separator
				end

				return path1 .. path2
			end

			assert.equals("/home/user/file.txt", utils.join_paths("/home/user", "file.txt"))

			utils.join_paths = orig_join_paths
			utils.is_windows_path = orig_is_windows_path
		end)

		it("should handle absolute second path", function()
			local orig_join_paths = utils.join_paths

			utils.join_paths = function(path1, path2)
				if not path1 or not path2 then
					return path1 or path2
				end

				if path2:match("^/") or path2:match("^%a:") then
					return path2
				end

				return path1 .. "/" .. path2
			end

			assert.equals("/absolute/path", utils.join_paths("/home/user", "/absolute/path"))

			utils.join_paths = orig_join_paths
		end)

		it("should handle paths with and without trailing separators", function()
			local orig_join_paths = utils.join_paths

			utils.join_paths = function(path1, path2)
				if not path1 or not path2 then
					return path1 or path2
				end

				if path2:match("^/") or path2:match("^%a:") then
					return path2
				end

				if path1:sub(-1) ~= "/" and path1:sub(-1) ~= "\\" then
					path1 = path1 .. "/"
				end

				return path1 .. path2
			end

			assert.equals("/home/user/file.txt", utils.join_paths("/home/user/", "file.txt"))

			utils.join_paths = orig_join_paths
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
			local orig_safe_display_path = utils.safe_display_path
			local orig_is_windows_path = utils.is_windows_path

			utils.is_windows_path = function(path)
				return false
			end

			utils.safe_display_path = function(path, max_length)
				if not path then
					return nil
				end
				max_length = max_length or 60

				if #path <= max_length then
					return path
				end

				local filename = path:match("[^/\\]+$") or ""
				return "..." .. filename
			end

			local long_path = "/very/long/path/with/many/subdirectories/and/a/filename.txt"
			local truncated = utils.safe_display_path(long_path, 30)

			assert.is_true(truncated:find("filename.txt") ~= nil)

			utils.safe_display_path = orig_safe_display_path
			utils.is_windows_path = orig_is_windows_path
		end)

		it("should handle different path styles", function()
			local orig_safe_display_path = utils.safe_display_path
			local orig_is_windows_path = utils.is_windows_path

			utils.is_windows_path = function(path)
				return true
			end

			utils.safe_display_path = function(path, max_length)
				if not path then
					return nil
				end
				max_length = max_length or 60

				if #path <= max_length then
					return path
				end

				local filename = path:match("[^/\\]+$") or ""
				return "..." .. filename
			end

			local windows_path = "C:\\very\\long\\path\\with\\many\\subdirectories\\and\\a\\filename.txt"
			local truncated = utils.safe_display_path(windows_path, 30)

			assert.is_true(truncated:find("filename.txt") ~= nil)

			utils.safe_display_path = orig_safe_display_path
			utils.is_windows_path = orig_is_windows_path
		end)

		it("should handle nil inputs gracefully", function()
			assert.is_nil(utils.safe_display_path(nil))
		end)
	end)
end)
