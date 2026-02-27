local nvim_tmux_wm = require('nvim-tmux-wm')

-- Create user commands for moving between splits
vim.api.nvim_create_user_command('NvimTmuxMoveLeft', function()
  nvim_tmux_wm.move('h')
end, {})

vim.api.nvim_create_user_command('NvimTmuxMoveDown', function()
  nvim_tmux_wm.move('j')
end, {})

vim.api.nvim_create_user_command('NvimTmuxMoveUp', function()
  nvim_tmux_wm.move('k')
end, {})

vim.api.nvim_create_user_command('NvimTmuxMoveRight', function()
  nvim_tmux_wm.move('l')
end, {})

-- Create user commands for resizing splits
vim.api.nvim_create_user_command('NvimTmuxResizeLeftBorderLeft', function(opts)
  local amount = tonumber(opts.args) or 3
  nvim_tmux_wm.resize('h', 'h', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeLeftBorderRight', function(opts)
  local amount = tonumber(opts.args) or 3
  nvim_tmux_wm.resize('h', 'l', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeRightBorderLeft', function(opts)
  local amount = tonumber(opts.args) or 3
  nvim_tmux_wm.resize('l', 'h', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeRightBorderRight', function(opts)
  local amount = tonumber(opts.args) or 3
  nvim_tmux_wm.resize('l', 'l', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeTopBorderUp', function(opts)
  local amount = tonumber(opts.args) or 1
  nvim_tmux_wm.resize('k', 'k', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeTopBorderDown', function(opts)
  local amount = tonumber(opts.args) or 1
  nvim_tmux_wm.resize('k', 'j', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeBottomBorderUp', function(opts)
  local amount = tonumber(opts.args) or 1
  nvim_tmux_wm.resize('j', 'k', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeBottomBorderDown', function(opts)
  local amount = tonumber(opts.args) or 1
  nvim_tmux_wm.resize('j', 'j', amount)
end, { nargs = '?' })
