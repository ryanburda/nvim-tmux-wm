#!/bin/sh
#
# Tmux resize script for nvim-tmux-wm
# Moves a specific border by a signed amount
#
# Args:
#   $1 - border_side: which border to move (h=left, j=bottom, k=top, l=right)
#   $2 - amount: signed integer; positive=right/up, negative=left/down
#
# Why not `tmux resize-pane`?
# ---------------------------
# `resize-pane` cannot express "move this border and nothing else":
#
# 1. It picks which border to move by walking up from the target pane to the
#    NEAREST container of the resize axis and moving the border after that
#    cell, falling back to the border before it when the cell is the last
#    child. In nested layouts this selects the wrong border. Example (the
#    current pane is B):
#
#      ┌─────┬─────┬────┐      "Move right border right" wants to move the
#      │  A  │  B  │    │      border with D, but B's nearest left-right
#      ├─────┴─────┤ D  │      container is {A,B} and B is its last cell, so
#      │     C     │    │      tmux falls back and moves the A|B border:
#      └───────────┴────┘      B's LEFT border.
#
# 2. Even when the right border moves, tmux redistributes the resized cell's
#    space round-robin among ALL its children, so in the example above the
#    border between [{A,B},C] and D can be moved but A and B both grow: B
#    appears to slide sideways instead of growing.
#
# So instead of resize-pane, this script edits the layout directly: it parses
# #{window_layout}, moves exactly one border in the layout tree (the growth
# or shrinkage is absorbed by the cells touching that border; every other
# border keeps its absolute position), and applies the result with
# `tmux select-layout`. When shrinking, panes at the border give up space
# first, cascading inward only when they hit tmux's minimum pane size.
#
# If the requested border is the window edge there is nothing to move and the
# script does nothing. Zoomed windows are left alone.

# Args
border_side=$1
amount=$2

# Current pane, window layout and zoom state, e.g.
#   "0 68f1,198x54,0,0{138x54,0,0[...],59x54,139,0,2} %13"
# `run-shell` (and every tmux pane) sets TMUX_PANE to the pane this script is
# acting on; prefer it over letting tmux guess the current pane.
info=$(tmux display-message ${TMUX_PANE:+-t "$TMUX_PANE"} -p '#{window_zoomed_flag} #{window_layout} #{pane_id}')

zoomed=${info%% *}
[ "$zoomed" = "1" ] && exit 0

layout=${info#* }
layout=${layout%% *}
layout=${layout#*,}                       # strip the leading checksum
active_pane=${info##* }
active_pane=${active_pane#%}              # pane number without the '%'

# Compute the new layout (with checksum), or nothing if the border can't move.
new_layout=$(awk -v layout="$layout" -v active="$active_pane" -v dir="$border_side" -v amount="$amount" '
  # Read an unsigned integer at the cursor.
  function readnum(  r) {
    r = ""
    while (pos <= len && substr(s, pos, 1) ~ /[0-9]/) {
      r = r substr(s, pos, 1)
      pos++
    }
    return r + 0
  }

  # Recursive-descent parser for the layout grammar:
  #   node     := WxH,X,Y ( "," pane_id | "{" nodelist "}" | "[" nodelist "]" )
  #   nodelist := node ( "," node )*
  # "{}" children are side by side (left-right), "[]" are stacked (top-bottom).
  function parse(par,   i, c, k) {
    i = ++n
    parent[i] = par
    w[i] = readnum(); pos++             # skip "x"
    h[i] = readnum(); pos++             # skip ","
    x[i] = readnum(); pos++             # skip ","
    y[i] = readnum()
    c = substr(s, pos, 1)
    if (c == "{" || c == "[") {
      type[i] = (c == "{") ? "lr" : "tb"
      pos++
      while (1) {
        k = parse(i)
        nchild[i]++
        child[i, nchild[i]] = k
        childpos[k] = nchild[i]
        if (substr(s, pos, 1) == ",") pos++
        else break
      }
      pos++                             # skip "}" or "]"
    } else {
      type[i] = "pane"
      pos++                             # skip ","
      paneid[i] = readnum()
    }
    return i
  }

  # Cell edges and size along the resize axis. "fwd" is the right/bottom
  # edge, "bwd" the left/top edge.
  function fwd_edge(i) { return axis == "lr" ? x[i] + w[i] : y[i] + h[i] }
  function bwd_edge(i) { return axis == "lr" ? x[i] : y[i] }
  function size(i)     { return axis == "lr" ? w[i] : h[i] }
  function addsize(i, d) { if (axis == "lr") w[i] += d; else h[i] += d }

  # How much a cell can shrink along the axis. A pane can go down to size 1
  # (tmux-s PANE_MINIMUM). Same-axis containers can drain all children;
  # opposite-axis containers are limited by their least flexible child,
  # since all children span the container on this axis.
  function capacity(i,   j, tot, m, c) {
    if (type[i] == "pane") return size(i) - 1
    if (type[i] == axis) {
      tot = 0
      for (j = 1; j <= nchild[i]; j++) tot += capacity(child[i, j])
      return tot
    }
    m = -1
    for (j = 1; j <= nchild[i]; j++) {
      c = capacity(child[i, j])
      if (m < 0 || c < m) m = c
    }
    return m
  }

  # Grow cell i by d, the moving edge being its "fwd" or "bwd" edge. Only
  # the child touching the moving edge absorbs the space, so no internal
  # border of a same-axis container moves. Opposite-axis children all span
  # the container and must all stretch.
  function grow(i, d, edge,   j) {
    addsize(i, d)
    if (type[i] == "pane") return
    if (type[i] != axis) {
      for (j = 1; j <= nchild[i]; j++) grow(child[i, j], d, edge)
      return
    }
    grow(child[i, edge == "fwd" ? nchild[i] : 1], d, edge)
  }

  # Shrink cell i by d (d never exceeds capacity(i)). The child touching the
  # moving edge gives up space first, cascading inward once it reaches
  # minimum size, like pushing panes ahead of the border.
  function shrink(i, d, edge,   j, k, t, step) {
    addsize(i, -d)
    if (type[i] == "pane") return
    if (type[i] != axis) {
      for (j = 1; j <= nchild[i]; j++) shrink(child[i, j], d, edge)
      return
    }
    if (edge == "fwd") { j = nchild[i]; step = -1 }
    else               { j = 1;         step =  1 }
    while (d > 0 && j >= 1 && j <= nchild[i]) {
      k = child[i, j]
      t = capacity(k)
      if (t > d) t = d
      if (t > 0) { shrink(k, t, edge); d -= t }
      j += step
    }
  }

  # Recompute every cell offset from the (possibly changed) sizes. Siblings
  # are separated by a one-cell border line.
  function offsets(i, X, Y,   j, k) {
    x[i] = X; y[i] = Y
    if (type[i] == "pane") return
    for (j = 1; j <= nchild[i]; j++) {
      k = child[i, j]
      offsets(k, X, Y)
      if (type[i] == "lr") X += w[k] + 1
      else                 Y += h[k] + 1
    }
  }

  function serialize(i,   r, j) {
    r = w[i] "x" h[i] "," x[i] "," y[i]
    if (type[i] == "pane") return r "," paneid[i]
    r = r (type[i] == "lr" ? "{" : "[")
    for (j = 1; j <= nchild[i]; j++)
      r = r (j > 1 ? "," : "") serialize(child[i, j])
    return r (type[i] == "lr" ? "}" : "]")
  }

  BEGIN {
    s = layout; len = length(s); pos = 1; n = 0
    root = parse(0)

    axis = (dir == "h" || dir == "l") ? "lr" : "tb"
    forward = (dir == "l" || dir == "j")   # moving the right/bottom border

    # Border movement in layout coordinates: x grows rightward but y grows
    # downward, while the user convention is positive=right/up.
    delta = (axis == "lr") ? amount : -amount
    if (delta == 0) exit

    # Find the active pane node.
    p0 = 0
    for (i = 1; i <= n; i++)
      if (type[i] == "pane" && paneid[i] == active) p0 = i
    if (!p0) exit

    # Walk up from the pane to find the cell "a" that owns the border: the
    # lowest ancestor (or the pane itself) sharing the pane-s edge that is a
    # non-last (forward) / non-first (backward) child of a same-axis
    # container. Ancestor edges only grow outward, so stop once the edge no
    # longer lines up. Reaching the root without a match means the border is
    # the window edge and cannot move.
    border = forward ? fwd_edge(p0) : bwd_edge(p0)
    a = 0
    cur = p0
    while (parent[cur] != 0) {
      if ((forward ? fwd_edge(cur) : bwd_edge(cur)) != border) break
      par = parent[cur]
      if (type[par] == axis) {
        if (forward && childpos[cur] < nchild[par]) { a = cur; break }
        if (!forward && childpos[cur] > 1)          { a = cur; break }
      }
      cur = par
    }
    if (!a) exit
    L = parent[a]

    # The cells before and after the border along the axis.
    if (forward) { bef = a; aft = child[L, childpos[a] + 1] }
    else         { bef = child[L, childpos[a] - 1]; aft = a }

    # Move the border, clamped to what the shrinking side can give up.
    if (delta > 0) {
      d = capacity(aft)
      if (d > delta) d = delta
      if (d <= 0) exit
      grow(bef, d, "fwd")
      shrink(aft, d, "bwd")
    } else {
      d = capacity(bef)
      if (d > -delta) d = -delta
      if (d <= 0) exit
      shrink(bef, d, "fwd")
      grow(aft, d, "bwd")
    }

    offsets(root, 0, 0)
    body = serialize(root)

    # tmux layout checksum: 16-bit rotate-right and add over the body.
    for (i = 32; i < 127; i++) ord[sprintf("%c", i)] = i
    csum = 0
    for (i = 1; i <= length(body); i++) {
      csum = int(csum / 2) + (csum % 2) * 32768
      csum = (csum + ord[substr(body, i, 1)]) % 65536
    }
    printf "%04x,%s\n", csum, body
  }
' 2>/dev/null)

[ -n "$new_layout" ] && \
  tmux select-layout ${TMUX_PANE:+-t "$TMUX_PANE"} "$new_layout" 2>/dev/null

exit 0
