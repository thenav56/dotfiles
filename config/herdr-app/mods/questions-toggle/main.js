// Open or close the question panel (mods/questions) in the focused tab.
// Bound in keys.json as `mod.open:questions-toggle`, and run by the Questions
// button in tabs-nav. Opens it to the right of the tab's agent (the one with a
// question round first, else an agent, else the focused pane) and hands it that
// terminal as its target; if the tab already has one, closes it instead.
//
// Live data is empty during init() of a freshly opened overlay, so this waits
// for it (like split-flip) and acts once, in a task.

import { View, div } from "gpui-kit";
import { props, closeOverlay, focused, panes, terminals, run, notify } from "herdr";

const LABEL = "questions.round";

export default class QuestionsToggle extends View {
  init(_props, cx) {
    this.started = false;
    cx.timer.every(50, (cx) => this.start(cx));
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  start(cx) {
    if (this.started || panes().length === 0) return;
    this.started = true;
    const f = focused();
    cx.spawn(async () => {
      try {
        this.toggle(f);
      } catch (e) {
        notify({ title: "Questions", body: String(e?.message ?? e), level: "warning", timeout: 4000 });
      }
      this.dismiss();
    });
  }

  toggle(f) {
    if (!f?.tab) throw new Error("no focused tab");
    const inTab = panes().filter((p) => p.tab === f.tab);
    const open = inTab.filter((p) => p.mod === "questions");
    if (open.length) {
      for (const p of open) run("pane.close", { pane: p.pane });
      return;
    }
    const hasRound = (address) => Boolean(terminals().find((t) => t.address === address)?.labels?.[LABEL]);
    const score = (p) => (hasRound(p.terminal) ? 4 : 0) + (p.status ? 2 : 0) + (p.focused ? 1 : 0);
    const best = inTab.filter((p) => p.terminal).sort((a, b) => score(b) - score(a))[0];
    if (!best) throw new Error("no terminal in this tab");
    run("pane.split", { direction: "right", pane: best.pane, mod: "questions", props: { target: best.terminal } });
  }

  render(cx) {
    this.start(cx);
    return div();
  }
}
