# nvim-tmux-navigator

Seamlessly navigate and resize between Neovim and tmux panes using a unified interface.
This plugin allows you to move between Neovim splits and tmux panes with the same keybindings,
and intelligently resize panes whether they're in Neovim or tmux.

## Features

- Navigate between Neovim splits and tmux panes with consistent keybindings
- Resize Neovim splits and tmux panes using the same interface
- Automatically detects whether to move/resize within Neovim or tmux
- Simple Lua API and user commands

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'ryanburda/nvim-tmux-navigator',
  config = function()
    require('nvim-tmux-navigator').setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'ryanburda/nvim-tmux-navigator',
  config = function()
    require('nvim-tmux-navigator').setup()
  end,
}
```

## Configuration

### Basic Setup

Call the setup function in your Neovim config:

```lua
require('nvim-tmux-navigator').setup()
```

This will create the user commands needed for navigation and resizing.

### Recommended Keymaps

Add these keymaps to your Neovim config for seamless navigation:

```lua
-- Navigation
vim.keymap.set('n', '<C-h>', '<cmd>NvimTmuxNavigateLeft<cr>')
vim.keymap.set('n', '<C-j>', '<cmd>NvimTmuxNavigateDown<cr>')
vim.keymap.set('n', '<C-k>', '<cmd>NvimTmuxNavigateUp<cr>')
vim.keymap.set('n', '<C-l>', '<cmd>NvimTmuxNavigateRight<cr>')

-- Resizing (optional)
vim.keymap.set('n', '<A-h>', '<cmd>NvimTmuxResizeLeft<cr>')
vim.keymap.set('n', '<A-j>', '<cmd>NvimTmuxResizeDown<cr>')
vim.keymap.set('n', '<A-k>', '<cmd>NvimTmuxResizeUp<cr>')
vim.keymap.set('n', '<A-l>', '<cmd>NvimTmuxResizeRight<cr>')
```

## Usage

### User Commands

After calling `setup()`, the following user commands are available:

**Navigation:**
- `:NvimTmuxNavigateLeft` - Move to the left split/pane
- `:NvimTmuxNavigateDown` - Move to the split/pane below
- `:NvimTmuxNavigateUp` - Move to the split/pane above
- `:NvimTmuxNavigateRight` - Move to the right split/pane

**Resizing:**
- `:NvimTmuxResizeLeft [amount]` - Resize left by `amount` (default: 5)
- `:NvimTmuxResizeDown [amount]` - Resize down by `amount` (default: 5)
- `:NvimTmuxResizeUp [amount]` - Resize up by `amount` (default: 5)
- `:NvimTmuxResizeRight [amount]` - Resize right by `amount` (default: 5)

Example with custom amount:
```vim
:NvimTmuxResizeLeft 10
```

### Lua API

You can also use the Lua API directly:

```lua
local navigator = require('nvim-tmux-navigator')

-- Move in a direction ('h', 'j', 'k', or 'l')
navigator.move('h')  -- Move left
navigator.move('j')  -- Move down
navigator.move('k')  -- Move up
navigator.move('l')  -- Move right

-- Resize in a direction with a specific amount
navigator.resize('h', 10)  -- Resize left by 10
navigator.resize('j', 5)   -- Resize down by 5
navigator.resize('k', 5)   -- Resize up by 5
navigator.resize('l', 10)  -- Resize right by 10
```

## How It Works

The plugin intelligently detects whether you're at the edge of a Neovim window:

- **Navigation:** When you navigate in a direction, it first tries to move to a Neovim split.
If there's no split in that direction, it moves to the adjacent tmux pane.

- **Resizing:** When resizing, it checks if there's a Neovim split in the specified direction
or the opposite direction. If a split exists, it resizes the Neovim split. If not, it resizes the tmux pane.

## License

MIT
