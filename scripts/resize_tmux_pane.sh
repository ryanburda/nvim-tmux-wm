#!/bin/sh
#
# Tmux resize script for nvim-tmux-wm
# Moves a specific border by a signed amount
#
# Args:
#   $1 - border_side: which border to move (h=left, j=bottom, k=top, l=right)
#   $2 - amount: signed integer; positive=right/up, negative=left/down
#
# The result of this script is a single tmux function call:
# ```sh
# tmux resize-pane [-t {left-of | up-of}] {-L | -R | -U | -D} absolute_amount 2>/dev/null
# ```
#
# `tmux resize-pane` always moves the bottom/right corner of the target pane. To move the
# left or top border, we target the neighbor pane via `{left-of}` or `{up-of}`, so that
# the neighbor's bottom-right corner (which is our shared border) gets moved.
#
# The absolute amount is needed because tmux resize-pane expects a direction
# flag (-L, -R, -U, -D) paired with a positive integer for the count.
# It doesn't accept negative counts.
#
#   args  | goal                       | tmux command
#   ------+----------------------------+------------------------------------------
#   h +N  | left border moves right    | tmux resize-pane -t {left-of} -R N
#   h -N  | left border moves left     | tmux resize-pane -t {left-of} -L N
#   j +N  | bottom border moves up     | tmux resize-pane -U N
#   j -N  | bottom border moves down   | tmux resize-pane -D N
#   k +N  | top border moves up        | tmux resize-pane -t {up-of} -U N
#   k -N  | top border moves down      | tmux resize-pane -t {up-of} -D N
#   l +N  | right border moves right   | tmux resize-pane -R N
#   l -N  | right border moves left    | tmux resize-pane -L N

# Args
border_side=$1
amount=$2

# Determine `resize_direction_flag` and `absolute_amount`.
if [ "$amount" -lt 0 ]; then
  absolute_amount=$((-amount))
  case $border_side in
    h|l) resize_direction_flag="-L" ;;
    j|k) resize_direction_flag="-D" ;;
  esac
else
  absolute_amount=$amount
  case $border_side in
    h|l) resize_direction_flag="-R" ;;
    j|k) resize_direction_flag="-U" ;;
  esac
fi

# Check if a pane exists at the border, then resize.
case $border_side in
  h)
    [ "$(tmux display-message -p '#{pane_at_left}')" -eq 0 ] && \
      tmux resize-pane -t {left-of} $resize_direction_flag $absolute_amount 2>/dev/null
    ;;
  j)
    [ "$(tmux display-message -p '#{pane_at_bottom}')" -eq 0 ] && \
      tmux resize-pane $resize_direction_flag $absolute_amount 2>/dev/null
    ;;
  k)
    [ "$(tmux display-message -p '#{pane_at_top}')" -eq 0 ] && \
      tmux resize-pane -t {up-of} $resize_direction_flag $absolute_amount 2>/dev/null
    ;;
  l)
    [ "$(tmux display-message -p '#{pane_at_right}')" -eq 0 ] && \
      tmux resize-pane $resize_direction_flag $absolute_amount 2>/dev/null
    ;;
esac

exit 0
