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
- Convert between path styles (Windows ↔ Unix)
- Transform paths to file URLs
- Interactive path preview window
- Copy to system clipboard
- Easy to use commands and keymaps
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
| `:PathConvertStyle` | Convert between Windows/Unix path styles |
| `:PathToUrl` | Convert path to file URL |
| `:PathPreview` | Show path preview window |

### Default Keymaps

The default keymaps use `<Leader>p` as prefix:

| Keymap | Action |
|--------|--------|
| `<Leader>pa` | Copy absolute path |
| `<Leader>pr` | Copy relative path |
| `<Leader>pp` | Copy project-relative path |
| `<Leader>pf` | Copy filename |
| `<Leader>pn` | Copy filename without extension |
| `<Leader>pd` | Copy directory path |
| `<Leader>pc` | Convert path style |
| `<Leader>pu` | Convert to file URL |
| `<Leader>po` | Open path preview window |

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

## API Usage

You can use the plugin's API in your Lua scripts:

```lua
local pathtool = require('pathtool')

-- Get paths
local abs_path = pathtool.get_absolute_path()
local rel_path = pathtool.get_relative_path()
local filename = pathtool.get_filename()

-- Convert paths
local converted = pathtool.convert_path_style(abs_path)
local file_url = pathtool.encode_path_as_url(abs_path)

-- Copy to clipboard
pathtool.copy_to_clipboard(abs_path)

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
