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

-- Advertise to tmux that this pane is running Neovim.
--
-- The tmux config needs to know whether to send a keypress through to Neovim or handle it
-- itself. Setting the `@pane-is-vim` pane option lets tmux check `if-shell -F '#{@pane-is-vim}'`,
-- which is a pure format expansion. The alternative is inspecting the pane's process list with
-- `ps`/`grep` on every keypress, which forks two processes per navigation and misidentifies the
-- pane whenever Neovim isn't the process tmux sees (`ssh`, `sudo nvim`, wrapper scripts).
if vim.env.TMUX ~= nil and vim.env.TMUX_PANE ~= nil then
  local pane = vim.env.TMUX_PANE

  local function set_pane_is_vim(is_vim)
    local cmd = is_vim
      and string.format("tmux set-option -p -t '%s' @pane-is-vim 1", pane)
      or string.format("tmux set-option -p -u -t '%s' @pane-is-vim", pane)
    os.execute(cmd .. ' 2>/dev/null')
  end

  local group = vim.api.nvim_create_augroup('NvimTmuxWm', { clear = true })

  -- FocusGained re-asserts the option so it self-heals if something else cleared it, such as a
  -- nested Neovim in a `:terminal` buffer unsetting it when the inner instance exits.
  vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume', 'FocusGained' }, {
    group = group,
    callback = function() set_pane_is_vim(true) end,
  })

  vim.api.nvim_create_autocmd({ 'VimLeave', 'VimSuspend' }, {
    group = group,
    callback = function() set_pane_is_vim(false) end,
  })
end
