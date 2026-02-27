local nvim_tmux_wm = require('nvim-tmux-wm')

-- Create user commands for moving between splits
vim.api.nvim_create_user_command('NvimTmuxNavigateLeft', function()
  nvim_tmux_wm.move('h')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateDown', function()
  nvim_tmux_wm.move('j')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateUp', function()
  nvim_tmux_wm.move('k')
end, {})

vim.api.nvim_create_user_command('NvimTmuxNavigateRight', function()
  nvim_tmux_wm.move('l')
end, {})

-- Create user commands for resizing splits
vim.api.nvim_create_user_command('NvimTmuxResizeLeft', function(opts)
  local amount = tonumber(opts.args) or 5
  nvim_tmux_wm.resize('h', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeDown', function(opts)
  local amount = tonumber(opts.args) or 5
  nvim_tmux_wm.resize('j', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeUp', function(opts)
  local amount = tonumber(opts.args) or 5
  nvim_tmux_wm.resize('k', amount)
end, { nargs = '?' })

vim.api.nvim_create_user_command('NvimTmuxResizeRight', function(opts)
  local amount = tonumber(opts.args) or 5
  nvim_tmux_wm.resize('l', amount)
end, { nargs = '?' })
