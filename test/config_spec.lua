local mock = require("luassert.mock")
local stub = require("luassert.stub")

_G.vim = {}

describe("pathtool.config", function()
	local config

	before_each(function()
		package.loaded["pathtool.config"] = nil

		config = require("pathtool.config")
	end)

	describe("defaults", function()
		it("should have default values", function()
			assert.is_table(config.defaults)
			assert.is_table(config.defaults.keymaps)
			assert.is_table(config.defaults.project_markers)
			assert.is_true(config.defaults.use_system_clipboard)
			assert.is_true(config.defaults.show_notifications)
			assert.equals(3000, config.defaults.notification_timeout)
			assert.equals(60, config.defaults.path_display_length)
		end)

		it("should have new default values for added features", function()
			assert.equals("middle", config.defaults.truncation_style)
			assert.equals("{action}: {path}", config.defaults.notification_format)
			assert.is_table(config.defaults.disabled_features)
			assert.equals(0, #config.defaults.disabled_features)
		end)
	end)

	describe("setup", function()
		it("should use defaults when no options are provided", function()
			config.setup()

			assert.equals(config.defaults.use_system_clipboard, config.options.use_system_clipboard)
			assert.equals(config.defaults.path_display_length, config.options.path_display_length)
			assert.equals(config.defaults.truncation_style, config.options.truncation_style)
			assert.equals(config.defaults.keymaps.copy_absolute_path, config.options.keymaps.copy_absolute_path)
		end)

		it("should override defaults with provided options", function()
			local custom_options = {
				use_system_clipboard = false,
				path_display_length = 80,
				truncation_style = "end",
				notification_format = "Custom: {path}",
				keymaps = {
					copy_absolute_path = "<leader>ca",
				},
				disabled_features = { "PathToUrl" },
			}

			config.setup(custom_options)

			assert.is_false(config.options.use_system_clipboard)
			assert.equals(80, config.options.path_display_length)
			assert.equals("end", config.options.truncation_style)
			assert.equals("Custom: {path}", config.options.notification_format)
			assert.equals("<leader>ca", config.options.keymaps.copy_absolute_path)
			assert.is_table(config.options.disabled_features)
			assert.equals(1, #config.options.disabled_features)
			assert.equals("PathToUrl", config.options.disabled_features[1])

			assert.equals(config.defaults.show_notifications, config.options.show_notifications)
			assert.equals(config.defaults.notification_timeout, config.options.notification_timeout)
		end)

		it("should deep merge tables like keymaps", function()
			local custom_options = {
				keymaps = {
					copy_absolute_path = "<leader>ca",
					copy_relative_path = "<leader>cr",
				},
			}

			config.setup(custom_options)

			assert.equals("<leader>ca", config.options.keymaps.copy_absolute_path)
			assert.equals("<leader>cr", config.options.keymaps.copy_relative_path)

			assert.equals("<leader>pf", config.options.keymaps.copy_filename)
			assert.equals("<leader>po", config.options.keymaps.open_preview)
		end)
	end)

	describe("get", function()
		before_each(function()
			config.setup({
				use_system_clipboard = false,
				path_display_length = 80,
			})
		end)

		it("should return the full options object when called without key", function()
			local options = config.get()
			assert.is_table(options)
			assert.equals(80, options.path_display_length)
			assert.is_false(options.use_system_clipboard)
		end)

		it("should return specific option value when called with key", function()
			assert.equals(80, config.get("path_display_length"))
			assert.is_false(config.get("use_system_clipboard"))
			assert.equals("middle", config.get("truncation_style"))
		end)

		it("should return nil for non-existent keys", function()
			assert.is_nil(config.get("non_existent_key"))
		end)
	end)

	describe("is_feature_enabled", function()
		it("should return true for enabled features", function()
			config.setup({
				disabled_features = { "PathToUrl", "copy_dirname" },
			})

			assert.is_true(config.is_feature_enabled("PathCopyAbsolute"))
			assert.is_true(config.is_feature_enabled("copy_filename"))
		end)

		it("should return false for disabled features", function()
			config.setup({
				disabled_features = { "PathToUrl", "copy_dirname" },
			})

			assert.is_false(config.is_feature_enabled("PathToUrl"))
			assert.is_false(config.is_feature_enabled("copy_dirname"))
		end)

		it("should handle empty disabled_features array", function()
			config.setup({
				disabled_features = {},
			})

			assert.is_true(config.is_feature_enabled("PathToUrl"))
			assert.is_true(config.is_feature_enabled("copy_dirname"))
		end)

		it("should handle nil disabled_features", function()
			config.setup({
				disabled_features = nil,
			})

			assert.is_true(config.is_feature_enabled("PathToUrl"))
			assert.is_true(config.is_feature_enabled("copy_dirname"))
		end)
	end)
end)
