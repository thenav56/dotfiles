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

-- Actions Rex lacks run scripts from commands/. The Mac app runs these on the
-- Mac's own server even for a pane on another host; ctx.server then names
-- that host and the script reaches it with `rex -S`. So remote hosts need no
-- config for these keys. Failures go to ~/.cache/rex-actions.log.
local HOME = os.getenv("HOME") or ""
local function run_script(script, ctx)
  if not ctx.session_id or not ctx.block_id then return end
  local argv = { HOME .. "/.dotfiles/commands/" .. script }
  if ctx.server and ctx.server ~= "" then
    argv[#argv + 1] = "-S"
    argv[#argv + 1] = ctx.server
  end
  for _, a in ipairs({ "-s", ctx.session_id, ctx.block_id }) do argv[#argv + 1] = a end
  local r = rex.exec(argv)
  if not r.ok then
    local line = string.format("%s server=%s session=%s block=%s code=%s %s",
      script, tostring(ctx.server), ctx.session_id, ctx.block_id,
      tostring(r.code), (r.stderr or ""):gsub("%s+$", ""))
    rex.exec { "/bin/sh", "-c",
      'mkdir -p "$HOME/.cache" && printf "%s %s\\n" "$(date "+%F %T")" "$1" >> "$HOME/.cache/rex-actions.log"',
      "sh", line }
  end
end

-- Flip split (side by side <-> stacked): cmd+e, like herdr's split-flip mod.
rex.action {
  name = "split_flip",
  title = "Flip Split",
  run = function(ctx) run_script("rex-split-flip", ctx) end,
}
rex.bind("cmd+e", "split_flip")

-- Close: cmd+w pane, cmd+shift+w tab
-- cmd+w: like herdr's pane-close mod. A bare shell closes at once; anything
-- running gets an Enter/Esc prompt (Rex's own close never asks).
rex.action {
  name = "pane_close",
  title = "Close Pane (Ask If Busy)",
  run = function(ctx) run_script("rex-pane-close", ctx) end,
}
rex.bind("cmd+w", "pane_close")
rex.bind("cmd+shift+w", "client.tab.close")
