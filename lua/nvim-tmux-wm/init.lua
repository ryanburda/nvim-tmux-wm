local T = {}

local nvim_to_tmux_direction_map = {
  ['h'] = 'L',
  ['j'] = 'D',
  ['k'] = 'U',
  ['l'] = 'R'
}

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

T.move_border = function(border_side, amount)
  local current_winnr = vim.fn.winnr()
  local border_winnr = vim.fn.winnr(border_side)

  if current_winnr == border_winnr then
    -- No nvim window at this border, delegate to tmux
    local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)") .. "../../scripts/resize_tmux_pane.sh"
    os.execute(string.format("tmux run-shell -b '%s %s %d' 2>/dev/null", script_path, border_side, amount))
  else
    -- Nvim window exists at this border, resize within nvim
    local is_horizontal_border = (border_side == 'j' or border_side == 'k')
    local resize_type = is_horizontal_border and '' or 'vertical '
    -- For vertical borders (h/l): positive=right(+), negative=left(-)
    -- For horizontal borders (j/k): positive=up(-), negative=down(+) — flipped because vim resize +N grows downward
    local sign = is_horizontal_border and (amount > 0 and '-' or '+') or (amount > 0 and '+' or '-')
    local target_winnr = (border_side == 'h' or border_side == 'k') and border_winnr or current_winnr
    vim.fn.win_execute(vim.fn.win_getid(target_winnr), string.format('silent! %sresize %s%d', resize_type, sign, math.abs(amount)))
  end
end

return T
