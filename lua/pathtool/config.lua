local M = {}

-- デフォルト設定
M.defaults = {
	keymaps = {
		copy_absolute_path = "<leader>pa",
		copy_relative_path = "<leader>pr",
		copy_filename = "<leader>pf",
		copy_dirname = "<leader>pd",
		copy_project_path = "<leader>pp",
		copy_filename_no_ext = "<leader>pn",
		convert_path_style = "<leader>pc",
		convert_to_url = "<leader>pu",
		open_preview = "<leader>po",
	},
	use_system_clipboard = true,
	show_notifications = true,
	notification_timeout = 3000,
	path_display_length = 60,
	detect_project_root = true,
	project_markers = {
		".git",
		".svn",
		"package.json",
		"Cargo.toml",
		"go.mod",
		"Makefile",
		".project",
		"CMakeLists.txt",
		"pyproject.toml",
	},
	-- 追加機能: カスタム通知フォーマット
	notification_format = "{action}: {path}",
	-- 追加機能: パスの切り詰め方法
	truncation_style = "middle", -- "middle", "start", "end"
	-- 追加機能: コマンド/キーマップの無効化
	disabled_features = {}, -- e.g. {"PathToUrl", "copy_dirname"}
}

-- 現在のユーザー設定
M.options = {}

-- 設定の初期化
M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

-- 設定値の取得
M.get = function(key)
	if key then
		return M.options[key]
	end
	return M.options
end

-- 機能が無効化されていないか確認
M.is_feature_enabled = function(feature_name)
	local disabled = M.options.disabled_features or {}
	for _, v in ipairs(disabled) do
		if v == feature_name then
			return false
		end
	end
	return true
end

return M
