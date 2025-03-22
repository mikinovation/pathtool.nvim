local config = require("pathtool.config")
local core = require("pathtool.core")
local ui = require("pathtool.ui")
local commands = require("pathtool.commands")

local M = {}

M.get_absolute_path = core.get_absolute_path
M.get_relative_path = core.get_relative_path
M.get_project_relative_path = core.get_project_relative_path
M.get_filename = core.get_filename
M.get_filename_without_ext = core.get_filename_without_ext
M.get_dirname = core.get_dirname
M.convert_path_style = core.convert_path_style
M.encode_path_as_url = core.encode_path_as_url
M.copy_to_clipboard = core.copy_to_clipboard
M.find_project_root = core.find_project_root
M.show_path_preview = ui.show_path_preview

M.setup = function(opts)
	config.setup(opts)
	commands.setup()
end

return M
