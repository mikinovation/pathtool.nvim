--- pathtool.nvim - A Neovim plugin for efficient file path manipulation
-- @module pathtool
-- @author mikinovation
-- @license MIT
-- @usage
-- ```lua
-- require('pathtool').setup({
--   -- your configuration options here
-- })
-- ```

local config = require("pathtool.config")
local core = require("pathtool.core")
local ui = require("pathtool.ui")
local commands = require("pathtool.commands")

local M = {}

--- Copies a text string to clipboard
-- @param text string Text to copy
-- @param type string (optional) Action type for notification (default: "Copied")
-- @return boolean Whether the copying was successful
M.copy_to_clipboard = core.copy_to_clipboard

--- Finds the project root directory based on marker files/directories
-- @param force_refresh boolean (optional) Whether to ignore the cache and refresh
-- @return string Project root directory or current working directory if not found
M.find_project_root = core.find_project_root

--- Shows a floating window with path preview
-- Displays all available path formats for the current file and
-- allows quick copying with single-key shortcuts
M.show_path_preview = ui.show_path_preview

--- Gets the absolute path of the current file
-- @return string|nil Absolute path or nil if no file is open
M.get_absolute_path = core.get_absolute_path

--- Gets the relative path of the current file from the current working directory
-- @return string|nil Relative path or nil if no file is open
M.get_relative_path = core.get_relative_path

--- Gets the path of the current file relative to the project root
-- @return string|nil Project-relative path or nil if no file is open
M.get_project_relative_path = core.get_project_relative_path

--- Gets the filename of the current file
-- @return string|nil Filename or nil if no file is open
M.get_filename = core.get_filename

--- Gets the filename without extension of the current file
-- @return string|nil Filename without extension or nil if no file is open
M.get_filename_without_ext = core.get_filename_without_ext

--- Gets the directory path of the current file
-- @return string|nil Directory path or nil if no file is open
M.get_dirname = core.get_dirname

--- Converts the path style of the current file (Unix ↔ Windows)
-- @return string|nil Converted path or nil if no file is open
M.convert_path_style = core.convert_path_style

--- Encodes the current file path as a file URL
-- @return string|nil File URL or nil if no file is open
M.encode_path_as_url = core.encode_path_as_url

--- Gets all file paths in the current file's directory
-- @return table A list of all file paths in the directory
M.get_all_directory_files = core.get_all_directory_files

--- Copies all file paths in the current directory to clipboard
-- @return boolean Whether the operation was successful
M.copy_directory_files = core.copy_directory_files

--- Sets up the plugin with user configuration
-- Initializes configuration and creates user commands
-- @param opts table|nil User options to merge with defaults
function M.setup(opts)
	config.setup(opts)
	commands.setup()
end

return M
