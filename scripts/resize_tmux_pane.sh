#!/bin/sh
# Tmux resize script for nvim-tmux-wm
# Moves a specific border by a signed amount
# Positive = right/up, Negative = left/down

border_side=$1
amount=$2

# Determine direction and absolute amount from sign
if [ "$amount" -lt 0 ]; then
  abs_amount=$((-amount))
  case $border_side in
    h|l) tmux_flag="-L" ;;
    j|k) tmux_flag="-D" ;;
  esac
else
  abs_amount=$amount
  case $border_side in
    h|l) tmux_flag="-R" ;;
    j|k) tmux_flag="-U" ;;
  esac
fi

# Check if a pane exists at the border, then resize
# Left/top borders target the neighbor pane; right/bottom borders target current pane
case $border_side in
  h)
    [ "$(tmux display-message -p '#{pane_at_left}')" -eq 0 ] && \
      tmux resize-pane -t {left-of} $tmux_flag $abs_amount 2>/dev/null
    ;;
  j)
    [ "$(tmux display-message -p '#{pane_at_bottom}')" -eq 0 ] && \
      tmux resize-pane $tmux_flag $abs_amount 2>/dev/null
    ;;
  k)
    [ "$(tmux display-message -p '#{pane_at_top}')" -eq 0 ] && \
      tmux resize-pane -t {up-of} $tmux_flag $abs_amount 2>/dev/null
    ;;
  l)
    [ "$(tmux display-message -p '#{pane_at_right}')" -eq 0 ] && \
      tmux resize-pane $tmux_flag $abs_amount 2>/dev/null
    ;;
esac

exit 0
