// Jump to a space: every space on every machine, in sidebar order. Type to
// filter (name, machine, branch); ↑/↓, ctrl+n/ctrl+p or mod+j/mod+k and Enter to go; Esc to leave.
// Bound in keys.json as `mod.open:space-switcher` (mod+shift+d).
//
// Mods can't import from outside their own folder, so the list code is shared
// with agent-switcher by copy; keep the two in step.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, agents, run, theme, props, closeOverlay, nextCommand, shared } from "herdr";

const ROW_H = 34;
const MAX_ROWS = 10;

// Same space colors as the stock mods (shared "space.colors"); read only.
const MARK = { ansi6: "#22a99a", ansi3: "#e3814f", ansi4: "#5b8def", ansi5: "#8b7cf6", ansi2: "#3fae6a", ansi1: "#d9649a" };
function spaceColor(t, s) {
  const c = (shared("space.colors") ?? {})[s.id];
  if (!c || s.name === "~") return t.dim;
  return c.startsWith("#") ? c : (MARK[c] ?? t[c] ?? t.dim);
}

export default class SpaceSwitcher extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = null;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Switch to space…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", () => this.pick(this.rows()[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    // keys.json "mod:space-switcher" sends "up"/"down" (mod+k / mod+j).
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

  move(by) {
    const n = this.rows().length || 1;
    this.at = ((this.at ?? 0) + by + n) % n;
  }

  dismiss() {
    const id = props()?.overlay;
    if (id) closeOverlay(id);
  }

  rows() {
    const f = this.filter.toLowerCase();
    return spaces().filter((s) => !f || [s.name, s.machine, s.branch].join(" ").toLowerCase().includes(f));
  }

  pick(s) {
    if (!s) return;
    this.dismiss();
    run("space.select", { id: s.id });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : st ? "●" : "");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    // Opens on the space you're in.
    if (this.at === null) this.at = Math.max(0, rows.findIndex((s) => s.active));
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const start = Math.max(0, Math.min(this.at - MAX_ROWS + 1, rows.length - MAX_ROWS));
    const shown = rows.slice(start, start + MAX_ROWS);
    const agentCount = new Map();
    for (const a of agents()) agentCount.set(a.space, (agentCount.get(a.space) ?? 0) + 1);

    const row = (s, i) => {
      const on = i === this.at;
      const tabs = `${s.tabs.length} tab${s.tabs.length === 1 ? "" : "s"}`;
      const n = agentCount.get(s.id) ?? 0;
      const where = [s.machine ?? "this computer", s.branch, tabs].filter(Boolean).join(" · ");
      return h_flex()
        .id(`ss-${s.id}`)
        .h(ROW_H)
        .px(10)
        .gap(10)
        .items_center()
        .rounded(7)
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((x) => x.bg(t.hover))
        .on_click(() => this.pick(s))
        .child(h_flex().size(18).flex_none().rounded(5).bg(spaceColor(t, s)).items_center().justify_center().text_size(10.5).font_bold().text_color("#ffffff").child([...s.name][0]?.toUpperCase() ?? "?"))
        .child(div().flex_1().truncate().text_color(t.foreground).when(s.active, (d) => d.font_semibold()).child(s.name))
        .when(s.status === "blocked", (el) => el.child(div().flex_none().text_size(11).text_color(t.blocked).child("needs you")))
        .when(s.status === "done", (el) => el.child(div().flex_none().text_size(11).text_color(t.done).child("finished")))
        .child(div().flex_none().max_w(240).truncate().text_size(11).text_color(t.dim).child(where))
        // Agents in the space (none: blank, so the column still lines up).
        .child(div().w(64).flex_none().text_right().text_size(11).text_color(n ? t.muted : t.dim).child(n ? `${n} agent${n === 1 ? "" : "s"}` : ""))
        .child(this.glyph(t, s.status));
    };

    return v_flex()
      .id("space-switcher")
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
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        rows.length
          ? v_flex().gap(0).children(shown.map((s, j) => row(s, start + j)))
          : div().px(10).py(8).text_color(t.dim).child("No matching spaces"),
      );
  }
}
