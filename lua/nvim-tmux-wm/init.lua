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
  local current_winnr = vim.fn.winnr()
  local direction_winnr = vim.fn.winnr(direction)

  if current_winnr ~= direction_winnr then
    -- Move to the nvim window in the specified direction
    vim.cmd('wincmd ' .. direction)
  else
    -- No nvim window to move to, move in tmux instead
    local handle = io.popen(string.format('tmux select-pane -%s 2>/dev/null', nvim_to_tmux_direction_map[direction]))
    if handle then
      handle:close()
    end
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

return T
