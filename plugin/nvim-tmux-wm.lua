local nvim_tmux_wm = require('nvim-tmux-wm')

-- Create user commands for navigating between splits
vim.api.nvim_create_user_command('NvimTmuxNavigateLeft', function()
  nvim_tmux_wm.navigate('h')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateDown', function()
  nvim_tmux_wm.navigate('j')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateUp', function()
  nvim_tmux_wm.navigate('k')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateRight', function()
  nvim_tmux_wm.navigate('l')
end, {})

-- Create user commands for resizing splits
-- Positive amount moves border right/up, negative moves border left/down
vim.api.nvim_create_user_command('NvimTmuxMoveLeftBorder', function(opts)
  local amount = tonumber(opts.args) or -3
  nvim_tmux_wm.move_border('h', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxMoveRightBorder', function(opts)
  local amount = tonumber(opts.args) or 3
  nvim_tmux_wm.move_border('l', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxMoveTopBorder', function(opts)
  local amount = tonumber(opts.args) or 1
  nvim_tmux_wm.move_border('k', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxMoveBottomBorder', function(opts)
  local amount = tonumber(opts.args) or -1
  nvim_tmux_wm.move_border('j', amount)
end, { nargs = '?' })
