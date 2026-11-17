// Show the Backlog tab: the one tab whose only pane is the `backlog` mod, in a
// local space named "Backlog" (the backlog spans every machine, a space lives
// on one). Run by the Backlog button in tabs-nav and by the "Archived to
// backlog" toast. Makes the space and the tab when they're missing.
//
// Live data is empty during init() of a freshly opened overlay, so this waits
// for it (like questions-toggle) and steps on a timer: a new space shows up in
// spaces() a moment after space.new.

import { View, div } from "gpui-kit";
import { props, closeOverlay, panes, spaces, run, notify } from "herdr";

const SPACE = "Backlog";
const MOD = "backlog";
const GIVE_UP_MS = 8000;

export default class BacklogOpen extends View {
  init(_props, cx) {
    this.step = "start";
    this.until = Date.now() + GIVE_UP_MS;
    cx.timer.every(80, (cx) => this.tick(cx));
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  done(msg) {
    if (this.step === "done") return;
    this.step = "done";
    if (msg) notify({ title: "Backlog", body: msg, level: "warning", timeout: 5000 });
    this.dismiss();
  }

  backlogSpace() {
    return spaces().find((s) => s.machine === null && s.named && s.name === SPACE);
  }

  tick() {
    if (this.step === "done" || panes().length === 0) return;
    if (Date.now() > this.until) return this.done("Couldn't open the Backlog tab.");
    try {
      const pane = panes().find((p) => p.mod === MOD);
      // The new space's starter shell tab goes once the mod tab is in.
      if (pane && this.shellTabs?.length) {
        for (const id of this.shellTabs) run("tab.close", { id, confirmed: true });
        this.shellTabs = [];
      }
      // Already there: show it.
      const home = pane && spaces().find((s) => s.tabs.some((t) => t.id === pane.tab));
      if (home) {
        run("space.select", { id: home.id });
        run("tab.select", { id: pane.tab });
        return this.done();
      }
      const space = this.backlogSpace();
      if (this.step === "start") {
        if (space) {
          run("tab.new", { space: space.id, name: SPACE, mod: MOD });
          this.step = "wait-tab";
        } else {
          // A space always starts with a terminal tab; it's closed once the mod tab is in.
          run("space.new", { name: SPACE, machine: "", tab: "shell" });
          this.step = "wait-space";
        }
        return;
      }
      if (this.step === "wait-space" && space) {
        this.shellTabs = space.tabs.map((t) => t.id);
        run("tab.new", { space: space.id, name: SPACE, mod: MOD });
        this.step = "wait-tab";
      }
      // wait-tab: the pane check at the top finishes.
    } catch (e) {
      this.done(String(e?.message ?? e));
    }
  }

  render() {
    return div();
  }
}
