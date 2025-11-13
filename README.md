# nvim-tmux-navigator

A Neovim plugin that makes Neovim splits and tmux panes indistinguishable from
a navigation and resizing perspective. Navigate and resize across the boundary
between Neovim and tmux as if they were a single, unified window manager.

![](./docs/nvim-tmux-navigator.gif)

## Navigation

Navigation works seamlessly across Neovim and tmux boundaries.
The default navigation keys are:
- `<C-h>` left
- `<C-j>` down
- `<C-k>` up
- `<C-l>` right

When any of these are pressed the plugin first attempts to move to an adjacent
Neovim split. If there's no split in that direction, it automatically moves to
the adjacent tmux pane instead. This creates a fluid navigation experience where
you never have to think about whether you're navigating within Neovim or between
tmux panes.

## Resizing

This plugin implements an intuitive resizing experience that differs from stock Neovim and tmux behavior.
The default resizing keys are:
- `<A-h>` grow left
- `<A-j>` grow down
- `<A-k>` grow up
- `<A-l>` grow right

### How It Works

The resize implementation **prioritizes making splits bigger**. Think of it as standing inside your
current pane and pushing the border in the specified direction outward to expand the current split.
A split will attempt to grow in the specified direction unless it is up against the outermost terminal window,
in which case it will shrink from the opposite direction.

When you resize:
1. **First priority**: The current split tries to grow by taking space from a neighbor in the direction you specify
2. **Fallback**: If you hit the edge of the container (terminal window), the split will shrink from the opposite direction instead
3. **Smart boundaries**: A Neovim split will never resize a tmux pane if there's another Neovim split it can take space from.
### Example

If you have splits arranged like this:
```
┌─────┬─────┐
│  A  │  B  │
├─────┼─────┤
│  C  │  D  │ ← You are here
└─────┴─────┘
```

When you press `<A-k>` (resize up) from split D:
- Split D will grow upward, taking space from split B
- The border between B and D moves up, making D larger

When you press `<A-j>` (resize down) from split D:
- Split D will shrink downward, giving more room to split B
- The border between B and D moves down, making D smaller

When you press `<A-h>` (resize left) from split D:
- Split D will grow to the left, taking space from split C
- The border between D and C moves to the left, making D larger

When you press `<A-l>` (resize right) from split D:
- Split D will shrink to the right, giving more room to split C
- The border between D and C moves to the right, making D smaller

In a more complicated case:
```
┌───────┐
│   A   │  
├───────┤
│   B   │ ← You are here
├───────┤
│   C   │
└───────┘
```

Split B is does not touch the either the top or bottom of the terminal window.

When you press `<A-k>` (resize up) from split B:
- Split B will grow upward, taking space from split A
- The border between B and A moves up, making B larger

When you press `<A-j>` (resize down) from split B:
- Split B will grow downward, taking space from split C
- The border between B and C moves down, making B larger

Notice that in this case, both resizing up and down made split B larger (unlike
in the first example where one direction grew and the other shrank). This is what
we mean by **prioritizing making splits bigger** - the plugin always attempts to
grow your current split first, regardless of direction.

This creates a more intuitive resizing experience where your action directly
corresponds to growing your current workspace in the direction you specify.

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
