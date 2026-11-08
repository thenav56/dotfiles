// Close the focused pane, asking first when something is running in it.
// Bound in keys.json as `mod.open:pane-close`. A bare shell at its prompt (or a
// mod pane) closes at once; anything else (an agent, nvim, a long command)
// gets an Enter/Esc dialog.
//
// Herdr's live data (focused(), panes()) is empty during init() of a freshly
// opened overlay; it arrives with the first render(). So the target is
// captured there, once, and acted on in a spawned task. Fails closed: if the
// focused pane can't be identified, nothing is closed, and pane.close always gets an explicit pane id.

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { run, props, closeOverlay, focused, panes, theme, notify } from "herdr";

export default class PaneClose extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.decided = false;
    this.pane = null;
    this.what = "a program";
  }

  // Runs on each render until the live data has arrived. Focus, overlays and
  // commands can't change during render, so the decision runs as a task.
  decide(cx) {
    if (this.decided) return;
    if (panes().length === 0) return; // not loaded yet
    this.decided = true;
    const paneId = focused()?.pane; // captured now, before anything moves focus
    cx.spawn(async (cx) => {
      this.act(paneId);
      cx.notify();
    });
  }

  act(paneId) {
    const info = paneId ? panes().find((p) => p.pane === paneId) : null;
    if (!info) {
      notify({ title: "Close pane", body: "No focused pane to close", level: "warning", timeout: 3000 });
      this.dismiss();
      return;
    }
    this.pane = info.pane;
    this.what = info.program?.name || info.title || "a program";
    // A mod pane has no terminal. A shell program means nothing in the
    // foreground; anything else, or a working agent, counts as running.
    const busy = info.terminal !== null && (!info.program?.shell || info.status === "working");
    if (busy) this.handle.focus();
    else this.closePane();
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  // Not `close()`: Herdr calls a View's close(cx) as cleanup whenever the
  // overlay goes away, which would close the pane on Esc/Cancel too.
  closePane() {
    this.dismiss();
    if (this.pane) run("pane.close", { pane: this.pane });
  }

  render(cx) {
    this.decide(cx);
    const t = theme();
    if (!this.pane) return div().size_full().bg(t.popover);
    const button = (id, label, bg, fg, onClick) =>
      h_flex().id(id).h(32).px(14).items_center().rounded(8).border_1().border_color(id === "no" ? t.input : bg).bg(bg).text_color(fg).cursor_pointer().hover((s) => s.opacity(0.88)).on_click(onClick).child(label);
    return v_flex()
      .id("pane-close")
      .track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "enter") this.closePane();
        else if (e.key === "escape") this.dismiss();
        else return;
        cx.stop_propagation();
      })
      .size_full()
      .min_h(0)
      .p(18)
      .gap(12)
      .bg(t.popover)
      .text_size(13)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Close pane?")).child(div().text_size(11).text_color(t.dim).child("Esc")))
      .child(div().flex_1().min_h(0).text_color(t.muted).child(`${this.what} is still running in it.`))
      .child(
        h_flex()
          .justify_end()
          .gap(8)
          .text_size(12)
          .child(button("no", "Cancel", t.raised, t.foreground, () => this.dismiss()))
          .child(button("yes", "Close", t.solid, t.solid_foreground, () => this.closePane())),
      );
  }
}
