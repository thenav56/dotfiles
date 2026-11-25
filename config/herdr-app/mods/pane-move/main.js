// Move the focused pane's terminal to another tab or space (it keeps running).
// Bound in keys.json as `mod.open:pane-move` (mod+shift+m); the pane header
// (pane-nav) has a button that focuses its pane and opens this.
//
// Rows: a new space, a new tab in each space, or beside the panes of an
// existing tab (Enter: right of it, Shift+Enter: below). Type to filter;
// ↑/↓, ctrl+n/ctrl+p or mod+j/mod+k; Esc to leave. Same machine only.
//
// Herdr has no move command, so commands/herdr-pane-move does it (park, then
// keep where it should go). The popup stays open, showing "Moving…", until
// that finishes: closing a mod cancels its pending calls.
//
// Live data (focused(), panes()) is empty during init() of a freshly opened
// overlay, so the source pane is captured on the first render that has it.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, focused, theme, props, closeOverlay, nextCommand, exec, home, notify } from "herdr";

const ROW_H = 34;
const MAX_ROWS = 12;

export default class PaneMove extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = 0;
    this.src = undefined; // undefined: not loaded yet; null: no terminal pane focused
    this.busy = false;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Move pane to…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", (e, cx) => this.pick(this.rows()[this.at], e?.shift ? "down" : "right", cx));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    // keys.json "mod:pane-move" sends "up"/"down" (mod+k / mod+j).
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "down") this.move(1);
        else if (c === "up") this.move(-1);
        else continue;
        cx.notify();
      }
    });
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  move(by) {
    const n = this.rows().length || 1;
    this.at = (this.at + by + n) % n;
  }

  capture() {
    if (this.src !== undefined || panes().length === 0) return;
    const info = panes().find((p) => p.pane === focused()?.pane);
    this.src = info?.terminal ? info : null;
  }

  // Every destination for the source pane, unfiltered.
  all() {
    const src = this.src;
    if (!src) return [];
    const all = spaces();
    const home = all.find((s) => s.tabs.some((t) => t.id === src.tab));
    if (!home) return [];
    const ps = panes();
    const alone = ps.filter((p) => p.tab === src.tab).length === 1;
    const rows = [{ kind: "space", label: "New space", hint: home.machine ?? "", icon: "plus" }];
    for (const s of all.filter((s) => s.machine === home.machine)) {
      // A lone pane as a new tab of its own space would only move the tab.
      if (!(s.id === home.id && alone)) rows.push({ kind: "tab", space: s, label: `New tab in ${s.name}`, hint: "", icon: "plus" });
      for (const t of s.tabs) {
        if (t.id === src.tab) continue;
        const terms = ps.filter((p) => p.tab === t.id && p.terminal);
        if (!terms.length) continue; // mod-only tab: nothing to split beside
        const what = terms.map((p) => (p.program?.agent && p.program.name) || p.title || p.program?.name).filter(Boolean);
        rows.push({ kind: "into", tab: t, label: `${s.name} › ${t.name}`, hint: [...new Set(what)].join(", "), icon: "panel-right", active: s.active && t.active });
      }
    }
    return rows;
  }

  rows() {
    const f = this.filter.toLowerCase();
    return this.all().filter((r) => !f || `${r.label} ${r.hint}`.toLowerCase().includes(f));
  }

  pick(r, place, cx) {
    if (!r || this.busy || !this.src) return;
    const args = [this.src.pane];
    if (r.kind === "space") args.push("--new-space", ...(this.src.cwd ? ["--folder", this.src.cwd] : []));
    else if (r.kind === "tab") args.push("--tab", r.space.id);
    else args.push("--into", r.tab.id, "--place", place);
    this.busy = true;
    cx.notify();
    cx.spawn(async () => {
      try {
        const res = await exec(`${home()}/.dotfiles/commands/herdr-pane-move`, args, { timeout: 30000 });
        if (res.code !== 0) throw new Error((res.stderr || res.stdout).trim().replace(/^herdr-pane-move: /, ""));
      } catch (e) {
        notify({ title: "Move pane", body: String(e?.message ?? e), level: "warning", timeout: 5000 });
      }
      this.dismiss();
    });
  }

  render(cx) {
    this.capture();
    const t = theme();
    if (this.busy) return div().size_full().p(18).bg(t.popover).text_size(13).text_color(t.muted).child("Moving…");
    const rows = this.rows();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const start = Math.max(0, Math.min(this.at - MAX_ROWS + 1, rows.length - MAX_ROWS));
    const shown = rows.slice(start, start + MAX_ROWS);
    const what = this.src ? (this.src.program?.agent && this.src.program.name) || this.src.title || "pane" : "";

    const row = (r, i) =>
      h_flex()
        .id(`pm-${i}`)
        .h(ROW_H)
        .px(10)
        .gap(10)
        .items_center()
        .rounded(7)
        .cursor_pointer()
        .when(i === this.at, (el) => el.bg(t.hover))
        .hover((x) => x.bg(t.hover))
        .on_click((e, cx) => this.pick(r, e.modifiers?.shift ? "down" : "right", cx))
        .child(svg(`mods/workspace-chrome/${r.icon}.svg`).size(14).flex_none().text_color(t.dim))
        .child(div().flex_1().truncate().text_color(t.foreground).when(r.kind !== "into", (d) => d.text_color(t.muted)).child(r.label))
        .child(div().flex_none().max_w(240).truncate().text_size(11).text_color(t.dim).child(r.hint));

    return v_flex()
      .id("pane-move")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(14)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return this.dismiss();
        if (k === "down" || (k === "n" && e.modifiers.control)) this.move(1);
        else if (k === "up" || (k === "p" && e.modifiers.control)) this.move(-1);
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground))
          .child(div().flex_none().max_w(180).truncate().text_size(11).text_color(t.dim).child(what)),
      )
      .child(
        this.src === null
          ? div().px(10).py(8).text_color(t.dim).child("No terminal pane focused")
          : rows.length
            ? v_flex().gap(0).children(shown.map((r, j) => row(r, start + j)))
            : div().px(10).py(8).text_color(t.dim).child(this.src ? "No matching place" : ""),
      )
      .child(div().px(10).text_size(11).text_color(t.dim).child("Enter: beside (right) · Shift+Enter: below"));
  }
}
