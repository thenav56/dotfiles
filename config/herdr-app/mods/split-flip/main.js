// Toggle the focused pane's split between side by side and stacked.
// Bound in keys.json as `mod.open:split-flip`. Herdr has no command for it, so
// this runs commands/herdr-split-flip (park the terminal, keep it back on the
// other axis) and stays open, invisibly, until that finishes.
//
// Live data (focused(), panes()) is empty during init() of a freshly opened
// overlay, so the target is read once it arrives (first render or timer tick
// that has it) and acted on in a task (state can't change during render).

import { View, div } from "gpui-kit";
import { props, closeOverlay, focused, panes, exec, home, notify } from "herdr";

export default class SplitFlip extends View {
  init(_props, cx) {
    this.started = false;
    // render() alone isn't enough: it may not run again while the window isn't
    // drawing, so poll too until the data is there.
    cx.timer.every(50, (cx) => this.start(cx));
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  start(cx) {
    if (this.started || panes().length === 0) return;
    this.started = true;
    const pane = focused()?.pane;
    cx.spawn(async () => {
      try {
        if (!pane) throw new Error("no focused pane");
        const r = await exec(`${home()}/.dotfiles/commands/herdr-split-flip`, [pane]);
        if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim().replace(/^herdr-split-flip: /, ""));
      } catch (e) {
        notify({ title: "Flip split", body: String(e?.message ?? e), level: "warning", timeout: 4000 });
      }
      this.dismiss();
    });
  }

  render(cx) {
    this.start(cx);
    return div();
  }
}
