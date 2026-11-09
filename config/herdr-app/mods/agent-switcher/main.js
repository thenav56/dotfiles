// Jump to an agent: every agent on every machine, ones that need you first
// (blocked, then finished), the rest in sidebar order. Type to filter (agent,
// title, space, tab, machine); ↑/↓, ctrl+n/ctrl+p or mod+j/mod+k and Enter to go; Esc to leave.
// Bound in keys.json as `mod.open:agent-switcher` (mod+d).
//
// Mods can't import from outside their own folder, so the list code is shared
// with space-switcher by copy; keep the two in step.

import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { agents, run, theme, props, closeOverlay, nextCommand } from "herdr";

const URGENT = { blocked: 0, done: 1 };
const ROW_H = 34;
const MAX_ROWS = 10;

// The agent's icon from the app's program table (as the stock agents mod draws it).
function icon(p, size, color) {
  if (!p?.icon) return null;
  return p.tint ? svg(p.icon).size(size).flex_none().text_color(color) : image(p.icon).w(size).h(size).flex_none();
}

const machineOf = (address) => (address.includes("/") ? address.split("/")[0] : null);

export default class AgentSwitcher extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = null;
    this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Switch to agent…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", () => this.pick(this.rows()[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    // keys.json "mod:agent-switcher" sends "up"/"down" (mod+k / mod+j).
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
    return agents()
      .map((a, i) => ({ a, i }))
      .filter(({ a }) => !f || [a.program?.name, a.title, a.space_name, a.tab_name, machineOf(a.address)].join(" ").toLowerCase().includes(f))
      .sort((x, y) => (URGENT[x.a.status] ?? 2) - (URGENT[y.a.status] ?? 2) || x.i - y.i)
      .map(({ a }) => a);
  }

  pick(a) {
    if (!a) return;
    this.dismiss();
    run("agent.focus", { terminal: a.address });
  }

  glyph(t, st) {
    if (st === "working") return svg("mods/workspace-chrome/spinner.svg").size(12).flex_none().text_color(t.working).spin(900);
    return div().w(12).flex_none().text_color(t[st] ?? t.dim).child(st === "idle" ? "○" : "●");
  }

  render() {
    const t = theme();
    const rows = this.rows();
    // Opens on the agent you're in.
    if (this.at === null) this.at = Math.max(0, rows.findIndex((a) => a.focused));
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const start = Math.max(0, Math.min(this.at - MAX_ROWS + 1, rows.length - MAX_ROWS));
    const shown = rows.slice(start, start + MAX_ROWS);

    const row = (a, i) => {
      const on = i === this.at;
      const machine = machineOf(a.address);
      const where = [machine, a.space_name, a.tab_name && `tab ${a.tab_name}`].filter(Boolean).join(" · ");
      return h_flex()
        .id(`as-${a.address}`)
        .h(ROW_H)
        .px(10)
        .gap(10)
        .items_center()
        .rounded(7)
        .cursor_pointer()
        .when(on, (el) => el.bg(t.hover))
        .hover((s) => s.bg(t.hover))
        .on_click(() => this.pick(a))
        .child(this.glyph(t, a.status))
        // Icon in place of the name ("Claude Code"); the name only when there's no icon.
        .child(icon(a.program, 16, t.foreground) ?? div().flex_none().text_color(t.foreground).child(a.program?.name ?? "agent"))
        .child(div().flex_1().truncate().text_size(12).text_color(a.focused ? t.foreground : t.muted).when(a.focused, (d) => d.font_semibold()).child(a.title ?? ""))
        .when(a.status === "blocked", (el) => el.child(div().flex_none().text_size(11).text_color(t.blocked).child("needs you")))
        .when(a.status === "done", (el) => el.child(div().flex_none().text_size(11).text_color(t.done).child("finished")))
        .child(div().flex_none().max_w(200).truncate().text_size(11).text_color(t.dim).child(where));
    };

    return v_flex()
      .id("agent-switcher")
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
          ? v_flex().gap(0).children(shown.map((a, j) => row(a, start + j)))
          : div().px(10).py(8).text_color(t.dim).child(this.filter ? "No matching agents" : "No agents running"),
      );
  }
}
