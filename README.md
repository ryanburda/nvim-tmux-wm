# nvim-tmux-wm

A unified window manager for Neovim and tmux.

Navigate and resize seamlessly across Neovim splits and tmux panes as if they were a single application.

![](./docs/nvim-tmux-wm.gif)

## Navigation

Navigation works seamlessly across Neovim and tmux boundaries.
The default navigation keys are:
- `<C-h>` move left
- `<C-j>` move down
- `<C-k>` move up
- `<C-l>` move right

These keybindings work seamlessly across Neovim and tmux boundaries, creating a
fluid navigation experience where you never have to think about whether you're
moving within Neovim or between tmux panes.

## Resizing

This plugin implements an intuitive split resizing experience that differs from stock Neovim and tmux behavior.
The default resizing keys are:
- `<A-h>` move left border left
- `<A-H>` move right border left
- `<A-j>` move bottom border down
- `<A-J>` move top border down
- `<A-k>` move top border up
- `<A-K>` move bottom border up
- `<A-l>` move right border right
- `<A-L>` move left border right

### How It Works

Each resize operation moves a **specific border** in a **specific direction**. There is no fallback
behavior — if the border doesn't exist (e.g. you're at the edge of the terminal window), nothing happens.

This gives you explicit, predictable control over your layout. Lowercase keys move the near border
(the one closest to the direction of the key), while uppercase keys move the far border.

### Example

If you have splits arranged like this:
```
┌─────┬─────┬─────┐
│  A  │  B  │  C  │
├─────┼─────┼─────┤
│  D  │  E  │  F  │
├─────┼─────┼─────┤
│  G  │  H  │  I  │
└─────┴─────┴─────┘
```

When inside split E:
- `<A-h>` moves the **left border left** → E grows, D shrinks
- `<A-H>` moves the **right border left** → E shrinks, F grows
- `<A-j>` moves the **bottom border down** → E grows, H shrinks
- `<A-J>` moves the **top border down** → E shrinks, B grows
- `<A-k>` moves the **top border up** → E grows, B shrinks
- `<A-K>` moves the **bottom border up** → E shrinks, H grows
- `<A-l>` moves the **right border right** → E grows, F shrinks
- `<A-L>` moves the **left border right** → E shrinks, D grows

# Configuration

`nvim-tmux-wm` is both a neovim plugin and a tmux plugin. As a result
we'll need to configure both ends in order to get things working.

**Why configure both Neovim and Tmux?**

This plugin requires configuration in both tmux and Neovim because they each
handle keybindings separately and our goal is to provide a unified experience:

- **Tmux side**: Tmux intercepts all keypresses first. The tmux configuration detects if the active pane
is running Neovim, and if so, passes the keypress through to Neovim. Otherwise, tmux handles the
navigation/resize itself.
- **Neovim side**: The plugin needs to be installed so Neovim can handle navigation/resize commands and
communicate with tmux when you're at a window edge.

Without the tmux configuration, your keypresses would only work within Neovim and wouldn't navigate to
tmux panes. Without the Neovim plugin, navigation from tmux into Neovim would work, but you couldn't
navigate back out to tmux panes from within Neovim.

## Neovim Setup

### Installation

#### Using [vim.pack](https://neovim.io/doc/user/lua.html#vim.pack)

```lua
vim.pack.add({ 'https://github.com/ryanburda/nvim-tmux-wm' })
```

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'ryanburda/nvim-tmux-wm' }
```

### Recommended Keymaps

Add these keymaps to your Neovim config for seamless navigation:

```lua
-- Navigation
vim.keymap.set('n', '<C-h>', '<cmd>NvimTmuxMoveLeft<cr>')
vim.keymap.set('n', '<C-j>', '<cmd>NvimTmuxMoveDown<cr>')
vim.keymap.set('n', '<C-k>', '<cmd>NvimTmuxMoveUp<cr>')
vim.keymap.set('n', '<C-l>', '<cmd>NvimTmuxMoveRight<cr>')

-- Resizing
vim.keymap.set('n', '<A-h>', '<cmd>NvimTmuxResizeLeftBorderLeft<cr>')
vim.keymap.set('n', '<A-H>', '<cmd>NvimTmuxResizeRightBorderLeft<cr>')
vim.keymap.set('n', '<A-j>', '<cmd>NvimTmuxResizeBottomBorderDown<cr>')
vim.keymap.set('n', '<A-J>', '<cmd>NvimTmuxResizeTopBorderDown<cr>')
vim.keymap.set('n', '<A-k>', '<cmd>NvimTmuxResizeTopBorderUp<cr>')
vim.keymap.set('n', '<A-K>', '<cmd>NvimTmuxResizeBottomBorderUp<cr>')
vim.keymap.set('n', '<A-l>', '<cmd>NvimTmuxResizeRightBorderRight<cr>')
vim.keymap.set('n', '<A-L>', '<cmd>NvimTmuxResizeLeftBorderRight<cr>')
```

## Tmux Setup

The tmux configuration needs to know where to find the [resize script](./scripts/resize_tmux_pane.sh)
that implements the resizing logic. This script is bundled with the Neovim plugin (rather than being
copy-pasted into your tmux config) to ensure both Neovim and tmux use identical, version-controlled
resize behavior. This ensures the window manager experience is kept consistent with future releases.

After installing the plugin with your Neovim package manager, update the `NVIM_TMUX_RESIZE_SCRIPT`
path in the configuration below to point to where the plugin was installed.

Add this configuration to your `~/.tmux.conf`:
```sh
################
# nvim-tmux-wm #
################
# NOTE: Update the path to match where you cloned this plugin (This should work for lazy.nvim)
#         |
#         |
#         V
NVIM_TMUX_RESIZE_SCRIPT="$HOME/.local/share/nvim/lazy/nvim-tmux-wm/scripts/resize_tmux_pane.sh"

is_vim="ps -o tty= -o state= -o comm= | grep -iqE '^#{s|/dev/||:pane_tty} +[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

# Navigation bindings
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

# Resize bindings
bind-key -n 'M-h' if-shell "$is_vim" 'send-keys M-h' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT h h 3'"
bind-key -n 'M-H' if-shell "$is_vim" 'send-keys M-H' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT l h 3'"
bind-key -n 'M-j' if-shell "$is_vim" 'send-keys M-j' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT j j 1'"
bind-key -n 'M-J' if-shell "$is_vim" 'send-keys M-J' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT k j 1'"
bind-key -n 'M-k' if-shell "$is_vim" 'send-keys M-k' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT k k 1'"
bind-key -n 'M-K' if-shell "$is_vim" 'send-keys M-K' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT j k 1'"
bind-key -n 'M-l' if-shell "$is_vim" 'send-keys M-l' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT l l 3'"
bind-key -n 'M-L' if-shell "$is_vim" 'send-keys M-L' "run-shell -b '$NVIM_TMUX_RESIZE_SCRIPT h l 3'"

# Legacy tmux version support for navigation
tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

# Copy mode bindings
bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
####################
# end nvim-tmux-wm #
####################
```

## Usage

After following the steps above, restart Neovim and tmux for the changes to take effect.

This plugin is best experienced through keymaps that unify the experience between Neovim and tmux.
Since tmux sends keys to Neovim it is rare that you will actually use the Neovim specific
navigation or resize commands directly.

### User Commands

The following user commands are available:

**Navigation:**
- `:NvimTmuxMoveLeft` - Move to the left split/pane
- `:NvimTmuxMoveDown` - Move to the split/pane below
- `:NvimTmuxMoveUp` - Move to the split/pane above
- `:NvimTmuxMoveRight` - Move to the right split/pane

**Resizing:**
- `:NvimTmuxResizeLeftBorderLeft [amount]` - Move the left border left by `amount` (default: 3)
- `:NvimTmuxResizeLeftBorderRight [amount]` - Move the left border right by `amount` (default: 3)
- `:NvimTmuxResizeRightBorderLeft [amount]` - Move the right border left by `amount` (default: 3)
- `:NvimTmuxResizeRightBorderRight [amount]` - Move the right border right by `amount` (default: 3)
- `:NvimTmuxResizeTopBorderUp [amount]` - Move the top border up by `amount` (default: 1)
- `:NvimTmuxResizeTopBorderDown [amount]` - Move the top border down by `amount` (default: 1)
- `:NvimTmuxResizeBottomBorderUp [amount]` - Move the bottom border up by `amount` (default: 1)
- `:NvimTmuxResizeBottomBorderDown [amount]` - Move the bottom border down by `amount` (default: 1)

Example with custom amount:
```vim
:NvimTmuxResizeLeftBorderLeft 10
```

### Lua API

You can also use the Lua API directly:

```lua
local nvim_tmux_wm = require('nvim-tmux-wm')

-- Move in a direction ('h', 'j', 'k', or 'l')
nvim_tmux_wm.move('h')  -- Move left
nvim_tmux_wm.move('j')  -- Move down
nvim_tmux_wm.move('k')  -- Move up
nvim_tmux_wm.move('l')  -- Move right

-- Resize: move a specific border in a specific direction
-- resize(border_side, move_direction, amount)
-- border_side: 'h' (left), 'j' (bottom), 'k' (top), 'l' (right)
-- move_direction: 'h' (left), 'j' (down), 'k' (up), 'l' (right)
nvim_tmux_wm.resize('h', 'h', 3)  -- Move left border left by 3
nvim_tmux_wm.resize('h', 'l', 3)  -- Move left border right by 3
nvim_tmux_wm.resize('l', 'h', 3)  -- Move right border left by 3
nvim_tmux_wm.resize('l', 'l', 3)  -- Move right border right by 3
nvim_tmux_wm.resize('k', 'k', 1)  -- Move top border up by 1
nvim_tmux_wm.resize('k', 'j', 1)  -- Move top border down by 1
nvim_tmux_wm.resize('j', 'k', 1)  -- Move bottom border up by 1
nvim_tmux_wm.resize('j', 'j', 1)  -- Move bottom border down by 1
```

## License

MIT
