-- Rex (Rex Beta.app) key bindings.
-- Pane keys mirror Herdr GUI (config/herdr-app/keys.json) so muscle memory carries over.
-- Check: `rex config check`  Apply: `rex config reload`  Inspect: `rex keymap`

-- Focus: cmd+hjkl / cmd+alt+arrows
rex.bind("cmd+h", "pane.focus.left")
rex.bind("cmd+j", "pane.focus.down")
rex.bind("cmd+k", "pane.focus.up")
rex.bind("cmd+l", "pane.focus.right")
rex.bind("cmd+alt+left", "pane.focus.left")
rex.bind("cmd+alt+down", "pane.focus.down")
rex.bind("cmd+alt+up", "pane.focus.up")
rex.bind("cmd+alt+right", "pane.focus.right")

-- Swap/move: cmd+shift+hjkl / cmd+alt+shift+arrows
rex.bind("cmd+shift+h", "pane.move.left")
rex.bind("cmd+shift+j", "pane.move.down")
rex.bind("cmd+shift+k", "pane.move.up")
rex.bind("cmd+shift+l", "pane.move.right")
rex.bind("cmd+alt+shift+left", "pane.move.left")
rex.bind("cmd+alt+shift+down", "pane.move.down")
rex.bind("cmd+alt+shift+up", "pane.move.up")
rex.bind("cmd+alt+shift+right", "pane.move.right")

-- Split: cmd+enter below, cmd+shift+enter right
rex.bind("cmd+enter", "pane.split.down")
rex.bind("cmd+shift+enter", "pane.split.right")

-- Zoom (pane fullscreen toggle): cmd+z
rex.bind("cmd+z", "pane.zoom")

-- Flip split (side by side <-> stacked): cmd+e, like herdr's split-flip mod.
-- Rex has no action for it; commands/rex-split-flip does it with `rex move`.
rex.action {
  name = "split_flip",
  title = "Flip Split",
  run = function(ctx)
    if not ctx.session_id or not ctx.block_id then return end
    rex.exec { (os.getenv("HOME") or "") .. "/.dotfiles/commands/rex-split-flip",
               "-s", ctx.session_id, ctx.block_id }
  end,
}
rex.bind("cmd+e", "split_flip")

-- Close: cmd+w pane, cmd+shift+w tab
-- cmd+w: like herdr's pane-close mod. A bare shell closes at once; anything
-- running gets an Enter/Esc prompt (Rex's own close never asks).
rex.action {
  name = "pane_close",
  title = "Close Pane (Ask If Busy)",
  run = function(ctx)
    if not ctx.session_id or not ctx.block_id then return end
    rex.exec { (os.getenv("HOME") or "") .. "/.dotfiles/commands/rex-pane-close",
               "-s", ctx.session_id, ctx.block_id }
  end,
}
rex.bind("cmd+w", "pane_close")
rex.bind("cmd+shift+w", "client.tab.close")
