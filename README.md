# nvim-tmux-navigator

Seamlessly navigate between Neovim and tmux panes using a unified interface.

![](./docs/nvim-tmux-navigator.gif)

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

### Setup

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

### Tmux setup

**Why configure both tmux and Neovim?**

This plugin requires configuration in both tmux and Neovim because they handle keybindings differently:

- **Neovim side**: The plugin needs to be installed so Neovim can handle navigation/resize commands and
communicate with tmux when you're at a window edge.
- **Tmux side**: Tmux intercepts all keypresses first. The tmux configuration detects if the active pane
is running Neovim, and if so, passes the keypress through to Neovim. Otherwise, tmux handles the
navigation/resize itself.

Without the tmux configuration, your keypresses would only work within Neovim and wouldn't navigate to
tmux panes. Without the Neovim plugin, navigation from tmux into Neovim would work, but you couldn't
navigate back out to tmux panes from within Neovim.

Add this configuration to your `~/.tmux.conf`:

**NOTE -** this assumes you are using the recommended keymaps above. Please modify as needed.
**NOTE -** `NVIM_TMUX_RESIZE_SCRIPT` path must be updated to be the location where this plugin was installed.
```sh
########################
# Nvim Tmux Navigation #
########################
is_vim="ps -o tty= -o state= -o comm= | grep -iqE '^#{s|/dev/||:pane_tty} +[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

# Navigation bindings
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

# Resize bindings
# NOTE: Update the path to match where you cloned this plugin (This should work for lazy.nvim)
# TODO: see if there is another way to do this besides specifying a path to a file.
NVIM_TMUX_RESIZE_SCRIPT="$HOME/.local/share/nvim/lazy/nvim-tmux-navigator/scripts/resize_tmux_pane.sh"

bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT L 3'"
bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT D 1'"
bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT U 1'"
bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT R 3'"

# Legacy tmux version support for navigation
tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

# Copy mode bindings
bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
############################
# End Nvim Tmux Navigation #
############################
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

## License

MIT
