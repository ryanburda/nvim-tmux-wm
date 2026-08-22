local T = {}

local nvim_to_tmux_direction_map = {
  ['h'] = 'L',
  ['j'] = 'D',
  ['k'] = 'U',
  ['l'] = 'R'
}

--- Navigate to the next window in the given direction, crossing into tmux if at the edge.
---@param direction string vim direction key: "h" (left), "j" (down), "k" (up), "l" (right)
T.navigate = function(direction)
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

--- Move a window border by a signed amount, crossing into tmux if at the edge.
---@param border_side string which border to move: "h" (left), "j" (bottom), "k" (top), "l" (right)
---@param amount integer signed offset; positive=right/up, negative=left/down
T.move_border = function(border_side, amount)
  local current_winnr = vim.fn.winnr()
  local border_winnr = vim.fn.winnr(border_side)

  if current_winnr == border_winnr then
    -- No nvim window at this border, delegate to tmux
    local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)") .. "../../scripts/resize_tmux_pane.sh"
    os.execute(string.format("tmux run-shell -b '%s %s %d' 2>/dev/null", script_path, border_side, amount))
  else
    -- Nvim window exists at this border, resize within nvim.
    --
    -- Move the border itself rather than growing/shrinking the current window. `resize` and
    -- `vertical resize` grow the window and let vim decide which neighbour donates the space,
    -- so the *opposite* border moves whenever the neighbour on the intended side can't give any
    -- up — it has 'winfixwidth'/'winfixheight' set, or is already at its minimum size.
    -- win_move_separator/win_move_statusline move one specific border, as if dragged by the mouse.
    --
    -- Both functions move the bottom/right border of the window they are given, so to move the
    -- left/top border we address the neighbour on that side instead.
    local target_winnr = (border_side == 'h' or border_side == 'k') and border_winnr or current_winnr
    local target_winid = vim.fn.win_getid(target_winnr)
    if border_side == 'h' or border_side == 'l' then
      -- positive=right, negative=left — same direction convention as win_move_separator
      vim.fn.win_move_separator(target_winid, amount)
    else
      -- positive=up, negative=down — inverted, win_move_statusline treats positive as down
      vim.fn.win_move_statusline(target_winid, -amount)
    end
  end
end

return T
