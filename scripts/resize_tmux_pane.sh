#!/bin/sh
# Smart tmux resize function for nvim-tmux-navigator
# This implements the same "push to grow" resize logic as the nvim plugin
# TODO: see if this can be put directy in tmux.conf

direction=$1
amount=$2

at_left=$(tmux display-message -p '#{pane_at_left}')
at_right=$(tmux display-message -p '#{pane_at_right}')
at_top=$(tmux display-message -p '#{pane_at_top}')
at_bottom=$(tmux display-message -p '#{pane_at_bottom}')

case $direction in
  L)
    if [ $at_left -eq 1 ] && [ $at_right -eq 1 ]; then
      :
    elif [ $at_left -eq 0 ] && [ $at_right -eq 1 ]; then
      tmux resize-pane -L $amount
    elif [ $at_left -eq 1 ] && [ $at_right -eq 0 ]; then
      tmux resize-pane -L $amount
    elif [ $at_left -eq 0 ] && [ $at_right -eq 0 ]; then
      tmux resize-pane -t {left-of} -L $amount
    fi
    ;;
  R)
    if [ $at_left -eq 1 ] && [ $at_right -eq 1 ]; then
      :
    elif [ $at_left -eq 1 ] && [ $at_right -eq 0 ]; then
      tmux resize-pane -R $amount
    elif [ $at_left -eq 0 ] && [ $at_right -eq 1 ]; then
      tmux resize-pane -R $amount
    elif [ $at_left -eq 0 ] && [ $at_right -eq 0 ]; then
      tmux resize-pane -t {right-of} -R $amount
    fi
    ;;
  U)
    if [ $at_top -eq 1 ] && [ $at_bottom -eq 1 ]; then
      :
    elif [ $at_top -eq 0 ] && [ $at_bottom -eq 1 ]; then
      tmux resize-pane -U $amount
    elif [ $at_top -eq 1 ] && [ $at_bottom -eq 0 ]; then
      tmux resize-pane -U $amount
    elif [ $at_top -eq 0 ] && [ $at_bottom -eq 0 ]; then
      tmux resize-pane -t {up-of} -U $amount
    fi
    ;;
  D)
    if [ $at_top -eq 1 ] && [ $at_bottom -eq 1 ]; then
      :
    elif [ $at_top -eq 1 ] && [ $at_bottom -eq 0 ]; then
      tmux resize-pane -D $amount
    elif [ $at_top -eq 0 ] && [ $at_bottom -eq 1 ]; then
      tmux resize-pane -D $amount
    elif [ $at_top -eq 0 ] && [ $at_bottom -eq 0 ]; then
      tmux resize-pane -t {down-of} -D $amount
    fi
    ;;
esac
