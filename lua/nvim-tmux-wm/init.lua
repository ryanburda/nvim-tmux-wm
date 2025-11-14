local T = {}

local nvim_opposite_direction_map = {
  ['h'] = 'l',
  ['j'] = 'k',
  ['k'] = 'j',
  ['l'] = 'h'
}

local nvim_to_tmux_direction_map = {
  ['h'] = 'L',
  ['j'] = 'D',
  ['k'] = 'U',
  ['l'] = 'R'
}

T.move = function(direction)
  local original_nvim_winnr = vim.fn.winnr()

  -- Try to move in the specified direction
  vim.cmd(string.format('wincmd %s', direction))

  -- Move tmux split if there wasn't a nvim split in that direction
  if vim.fn.winnr() == original_nvim_winnr then
    local handle = io.popen(string.format('tmux select-pane -%s 2>/dev/null', nvim_to_tmux_direction_map[direction]))
    local result = handle:read("*a")
    handle:close()
  end
end

T.resize = function(direction, amount)
  --[[
  This resize implementation prioritizes making splits bigger.

  You can think of this as if you were standing inside the current
  pane and pushing the border in the specified direction out to make
  the size of the current split larger.

  In the event that you cannot push that border any further, meaning
  you hit the frame of the entire container (terminal window), the
  split will shrink from the opposite direction.

  A nvim split will never resize a tmux split if there is another nvim split it can take from.
  A tmux split will never resize a nvim split if there is another tmux split it can take from.
  ]]

  local direction_str = 'horizontal'
  if direction == 'h' or direction == 'l' then
    direction_str = 'vertical'
  end

  -- Get the current window number
  local current_winnr = vim.fn.winnr()

  -- In order to know which way an nvim window should grow we first need to find out what windows exist around it.
  --
  -- Get the window number of the window in the specified direction and opposite the specified direction.
  -- For example, `resize('k', 5)` will check if there is a window both above and below.
  --
  -- NOTE: `vim.fn.winnr(direction)` returns the current winnr if there is no window in that direction.
  local direction_winnr = vim.fn.winnr(direction)
  local opposite_direction_winnr = vim.fn.winnr(nvim_opposite_direction_map[direction])

  if current_winnr == direction_winnr and current_winnr == opposite_direction_winnr then
    -- Resize the tmux pane if there isn't a nvim split on either side of the current split.
    -- Get the path to the resize script
    -- TODO: fix how tmux resizing is called.
    local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)") .. "../../scripts/resize_tmux_pane.sh"
    os.execute(string.format("tmux run-shell -b '%s %s %d' 2>/dev/null", script_path, nvim_to_tmux_direction_map[direction], amount))
  elseif current_winnr ~= direction_winnr and current_winnr == opposite_direction_winnr then
    if direction == 'j' or direction == 'l' then
      vim.fn.win_execute(vim.fn.win_getid(current_winnr), string.format('%s resize +%d', direction_str, amount))
    else
      vim.fn.win_execute(vim.fn.win_getid(direction_winnr), string.format('%s resize -%d', direction_str, amount))
    end
  elseif current_winnr == direction_winnr and current_winnr ~= opposite_direction_winnr then
    if direction == 'j' or direction == 'l' then
      vim.fn.win_execute(vim.fn.win_getid(opposite_direction_winnr), string.format('%s resize +%d', direction_str, amount))
    else
      vim.fn.win_execute(vim.fn.win_getid(current_winnr), string.format('%s resize -%d', direction_str, amount))
    end
  elseif current_winnr ~= direction_winnr and current_winnr ~= opposite_direction_winnr then
    if direction == 'j' or direction == 'l' then
      vim.fn.win_execute(vim.fn.win_getid(current_winnr), string.format('%s resize +%d', direction_str, amount))
    else
      vim.fn.win_execute(vim.fn.win_getid(direction_winnr), string.format('%s resize -%d', direction_str, amount))
    end
  end

end

T.setup = function()
  -- Create user commands for moving between splits
  vim.api.nvim_create_user_command('NvimTmuxNavigateLeft', function()
    T.move('h')
  end, {})

  vim.api.nvim_create_user_command('NvimTmuxNavigateDown', function()
    T.move('j')
  end, {})

  vim.api.nvim_create_user_command('NvimTmuxNavigateUp', function()
    T.move('k')
  end, {})

  vim.api.nvim_create_user_command('NvimTmuxNavigateRight', function()
    T.move('l')
  end, {})

  -- Create user commands for resizing splits
  vim.api.nvim_create_user_command('NvimTmuxResizeLeft', function(opts)
    local amount = tonumber(opts.args) or 5
    T.resize('h', amount)
  end, { nargs = '?' })

  vim.api.nvim_create_user_command('NvimTmuxResizeDown', function(opts)
    local amount = tonumber(opts.args) or 5
    T.resize('j', amount)
  end, { nargs = '?' })

  vim.api.nvim_create_user_command('NvimTmuxResizeUp', function(opts)
    local amount = tonumber(opts.args) or 5
    T.resize('k', amount)
  end, { nargs = '?' })

  vim.api.nvim_create_user_command('NvimTmuxResizeRight', function(opts)
    local amount = tonumber(opts.args) or 5
    T.resize('l', amount)
  end, { nargs = '?' })
end

return T
