#!/bin/sh
# Tmux resize script for nvim-tmux-wm
# Moves a specific border in a specific direction

border_side=$1
move_dir=$2
amount=$3

# Map vim-style direction to tmux flag
case $move_dir in
  h) tmux_flag="-L" ;;
  j) tmux_flag="-D" ;;
  k) tmux_flag="-U" ;;
  l) tmux_flag="-R" ;;
esac

# Check if a pane exists at the border, then resize
# Left/top borders target the neighbor pane; right/bottom borders target current pane
case $border_side in
  h)
    [ "$(tmux display-message -p '#{pane_at_left}')" -eq 0 ] && \
      tmux resize-pane -t {left-of} $tmux_flag $amount 2>/dev/null
    ;;
  j)
    [ "$(tmux display-message -p '#{pane_at_bottom}')" -eq 0 ] && \
      tmux resize-pane $tmux_flag $amount 2>/dev/null
    ;;
  k)
    [ "$(tmux display-message -p '#{pane_at_top}')" -eq 0 ] && \
      tmux resize-pane -t {up-of} $tmux_flag $amount 2>/dev/null
    ;;
  l)
    [ "$(tmux display-message -p '#{pane_at_right}')" -eq 0 ] && \
      tmux resize-pane $tmux_flag $amount 2>/dev/null
    ;;
esac

exit 0
