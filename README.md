# pathtool.nvim

A Neovim plugin for efficient file path manipulation, providing simple ways to copy, convert, and preview file paths.

## Features

- Copy file paths in various formats:
  - Absolute path
  - Relative path (from current working directory)
  - Project-relative path (from project root)
  - Filename only
  - Filename without extension
  - Directory path
  - All files in current directory (recursively)
- Convert between path styles (Windows ↔ Unix)
- Transform paths to file URLs
- Interactive path preview window
- Copy to system clipboard
- Easy to use commands
- Project root detection

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'mikinovation/pathtool.nvim',
  config = function()
    -- Optional: customization
    require('pathtool').setup({
      -- your configuration here (see Configuration section)
    })
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'mikinovation/pathtool.nvim',
  config = function()
    -- Optional: customization
    require('pathtool').setup({
      -- your configuration here
    })
  end
}
```

### Using Vim-Plug

```vim
Plug 'mikinovation/pathtool.nvim'
```

After installation, add to your `init.lua` (optional):

```lua
require('pathtool').setup({
  -- customization options
})
```

Or in `init.vim`:

```vim
lua << EOF
require('pathtool').setup({
  -- customization options
})
EOF
```

## Usage

### Commands

The plugin provides the following commands:

| Command | Description |
|---------|-------------|
| `:PathCopyAbsolute` | Copy absolute path to clipboard |
| `:PathCopyRelative` | Copy relative path to clipboard |
| `:PathCopyProject` | Copy project-relative path to clipboard |
| `:PathCopyFilename` | Copy filename to clipboard |
| `:PathCopyFilenameNoExt` | Copy filename without extension |
| `:PathCopyDirname` | Copy directory path to clipboard |
| `:PathCopyDirectoryFiles` | Copy paths of all files in current directory |
| `:PathConvertStyle` | Convert between Windows/Unix path styles |
| `:PathToUrl` | Convert path to file URL |
| `:PathPreview` | Show path preview window |

### Keymaps

This plugin does not set up any keymaps automatically. You can define your own keymaps to call the plugin commands.

Example of setting up keymaps in your Neovim configuration:

```lua
-- Map keys directly to commands
vim.keymap.set('n', '<leader>pa', ':PathCopyAbsolute<CR>', { desc = "Copy absolute path", silent = true })
vim.keymap.set('n', '<leader>pr', ':PathCopyRelative<CR>', { desc = "Copy relative path", silent = true })
vim.keymap.set('n', '<leader>pp', ':PathCopyProject<CR>', { desc = "Copy project-relative path", silent = true })
vim.keymap.set('n', '<leader>pf', ':PathCopyFilename<CR>', { desc = "Copy filename", silent = true })
vim.keymap.set('n', '<leader>pn', ':PathCopyFilenameNoExt<CR>', { desc = "Copy filename without extension", silent = true })
vim.keymap.set('n', '<leader>pd', ':PathCopyDirname<CR>', { desc = "Copy directory path", silent = true })
vim.keymap.set('n', '<leader>pD', ':PathCopyDirectoryFiles<CR>', { desc = "Copy all files in directory", silent = true })
vim.keymap.set('n', '<leader>pc', ':PathConvertStyle<CR>', { desc = "Convert path style", silent = true })
vim.keymap.set('n', '<leader>pu', ':PathToUrl<CR>', { desc = "Convert to file URL", silent = true })
vim.keymap.set('n', '<leader>po', ':PathPreview<CR>', { desc = "Open path preview", silent = true })
```

You can use any key combinations that suit your workflow.

### Path Preview Window

The path preview window shows all available path formats and lets you copy them with a single keystroke:

- `a` - Copy absolute path
- `r` - Copy relative path
- `p` - Copy project relative path
- `f` - Copy filename
- `n` - Copy filename without extension
- `d` - Copy directory path
- `c` - Copy converted path style
- `u` - Copy file URL
- `D` - Copy all files in directory
- `q` or `<Esc>` - Close window

## Configuration

Configure the plugin using the `setup()` function:

```lua
require('pathtool').setup({
  use_system_clipboard = true,
  show_notifications = true,
  notification_timeout = 3000,
  path_display_length = 60,
  detect_project_root = true,
  project_markers = {
    '.git', '.svn', 'package.json', 'Cargo.toml', 'go.mod', 
    'Makefile', '.project', 'CMakeLists.txt', 'pyproject.toml'
  },
  directory_files = {
    max_files = 1000,
    max_depth = 5,
    ignored_patterns = {
      "%.git",
      "node_modules",
      "%.DS_Store",
      "%.cache",
      "build",
      "dist"
    },
    include_directories = false,
    relative_paths = true,
  },
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `use_system_clipboard` | boolean | `true` | Copy to system clipboard (+ register) |
| `show_notifications` | boolean | `true` | Show notifications when copying paths |
| `notification_timeout` | number | `3000` | Notification timeout in milliseconds |
| `path_display_length` | number | `60` | Max length for paths in notifications |
| `detect_project_root` | boolean | `true` | Enable project root detection |
| `project_markers` | table | see above | Files/directories that identify project root |
| `directory_files` | table | see above | Configuration for directory files listing |
| `directory_files.max_files` | number | `1000` | Maximum number of files to retrieve |
| `directory_files.max_depth` | number | `5` | Maximum directory depth to traverse |
| `directory_files.ignored_patterns` | table | see above | Patterns to ignore when listing files |
| `directory_files.include_directories` | boolean | `false` | Whether to include directories in the result |
| `directory_files.relative_paths` | boolean | `true` | Use paths relative to the current directory |

## API Usage

You can use the plugin's API in your Lua scripts:

```lua
local pathtool = require('pathtool')

-- Get paths
local abs_path = pathtool.get_absolute_path()
local rel_path = pathtool.get_relative_path()
local filename = pathtool.get_filename()

-- Get directory files
local dir_files = pathtool.get_all_directory_files()

-- Convert paths
local converted = pathtool.convert_path_style()
local file_url = pathtool.encode_path_as_url()

-- Copy to clipboard
pathtool.copy_to_clipboard(abs_path)
pathtool.copy_directory_files()

-- Show preview window
pathtool.show_path_preview()
```

The plugin also provides a set of utilities for path manipulation:

```lua
local utils = require('pathtool.utils')

-- Detect OS and paths
local is_win = utils.is_windows()
local is_win_path = utils.is_windows_path(path)

-- Normalize and convert paths
local normalized = utils.normalize_path(path)
local native_path = utils.to_native_path(path)

-- Path manipulations
local joined = utils.join_paths(path1, path2)
local parent = utils.path_up(path, 1)
local new_ext = utils.change_extension(path, 'js')
```

## Requirements

- Neovim 0.10.0 or higher

## License

MIT License
