// Put a Claude Code agent's session away in the backlog, or edit a backlog entry.
// Opened as a dialog by the archive button on an Agents row (agents-nav) with
// props {address, pane, machine, title, meta}, and by Edit in the Backlog tab
// (mods/backlog) with props {edit: true, machine, id, title, note}.
//
// The work is `claude-as backlog add|edit` on the agent's machine (see
// docs/claude-as.md): add refuses while claude works or a Bash-tool shell runs
// (the reasons show here), protects and backs up the session, then stops claude;
// this closes the pane once it has. Shared "backlog.rev" tells the Backlog tab to reload.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { exec, hc, run, props, closeOverlay, theme, notify, setShared, checking } from "herdr";

// hc runs commands without a login shell: put claude-as (~/.local/bin), uv and
// claude-custom on PATH.
const CLAUDE_AS = 'PATH="$HOME/.local/bin:$HOME/.dotfiles/commands:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" exec claude-as "$@"';

// Runs `claude-as <args>` on `on` (null: this computer); resolves with its JSON line.
async function claudeAs(args, on) {
  const r = await exec("sh", ["-c", CLAUDE_AS, "sh", ...args], { on: on ?? null, timeout: 60000 });
  const line = r.stdout.trim().split("\n").filter(Boolean).pop() ?? "";
  try {
    return JSON.parse(line);
  } catch {
    throw new Error((r.stderr || r.stdout || `claude-as exited ${r.code}`).trim().slice(-600));
  }
}

export default class BacklogArchive extends View {
  init(_props, cx) {
    this.p = props() ?? {};
    this.edit = Boolean(this.p.edit);
    this.working = false;
    this.error = null;
    this.reasons = [];
    this.title = InputState.new({ placeholder: "Title", value: this.p.title ?? "" });
    this.note = InputState.new({ placeholder: "Note (optional)", value: this.p.note ?? "" });
    for (const s of [this.title, this.note]) s.on("submit", (_e, cx) => this.submit(cx));
    this.title.focus();
    cx.timer.after(300, () => this.title.focus());
  }

  dismiss() {
    const id = this.p.overlay ?? props()?.overlay;
    if (id) closeOverlay(id);
  }

  submit(cx) {
    if (this.working || checking()) return;
    this.working = true;
    this.error = null;
    this.reasons = [];
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        if (this.edit) await this.save();
        else await this.archive();
        setShared("backlog.rev", Date.now());
        this.dismiss();
      } catch (e) {
        this.error = String(e?.message ?? e);
        this.reasons = e?.reasons ?? [];
      }
      this.working = false;
      cx.notify();
    });
  }

  async archive() {
    const { address, pane, machine, meta } = this.p;
    // The terminal's foreground process: claude itself, or a launcher above it
    // (`uv run claude-as default`); claude-as finds claude at or below it.
    const got = await hc(["get", address, "--json"]);
    let info = null;
    try {
      info = JSON.parse(got.stdout);
    } catch {}
    const pid = info?.foreground?.pid ?? info?.pid;
    if (!pid) throw new Error(`Can't find the process running in ${address}.`);
    const out = await claudeAs(
      ["backlog", "add", "--pid", String(pid), "--title", this.title.value().trim(), "--note", this.note.value().trim(), "--meta", JSON.stringify(meta ?? {})],
      machine,
    );
    if (!out.ok) {
      const err = new Error(out.error ?? "claude-as backlog add failed");
      err.reasons = out.busy ?? [];
      throw err;
    }
    if (out.killed && pane) run("pane.close", { pane });
    notify({
      title: "Archived to backlog",
      body: out.killed ? out.entry?.title : `${out.entry?.title} (saved, but claude didn't stop; close the pane yourself)`,
      level: out.killed ? "success" : "warning",
      timeout: 4000,
      action: { name: "mod.open", args: { name: "backlog-open" } },
    });
  }

  async save() {
    const out = await claudeAs(["backlog", "edit", this.p.id, "--title", this.title.value().trim(), "--note", this.note.value().trim()], this.p.machine);
    if (!out.ok) throw new Error(out.error ?? "claude-as backlog edit failed");
  }

  render() {
    const t = theme();
    const field = (label, state) =>
      v_flex()
        .gap(5)
        .child(div().text_size(11).text_color(t.dim).child(label))
        .child(h_flex().h(32).px(10).items_center().rounded(7).border_1().border_color(t.input).bg(t.background).child(Input.new(state).flex_1().h_full().text_size(12.8).text_color(t.foreground)));
    const button = (id, label, primary, onClick) =>
      h_flex()
        .id(id)
        .h(30)
        .px(14)
        .items_center()
        .rounded(7)
        .border_1()
        .border_color(primary ? t.solid : t.input)
        .bg(primary ? t.solid : t.raised)
        .text_color(primary ? t.solid_foreground : t.foreground)
        .cursor_pointer()
        .hover((s) => s.opacity(0.88))
        .on_click((_e, cx) => onClick(cx))
        .child(label);
    const where = this.p.machine ? ` on ${this.p.machine}` : "";
    return v_flex()
      .id("backlog-archive")
      .size_full()
      .min_h(0)
      .p(18)
      .gap(12)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        if (e.key !== "escape") return;
        cx.stop_propagation();
        this.dismiss();
      })
      .child(
        h_flex()
          .items_center()
          .gap(8)
          .child(svg("mods/workspace-chrome/archive.svg").size(15).text_color(t.muted))
          .child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child(this.edit ? "Edit backlog entry" : `Archive to backlog${where}`))
          .child(div().text_size(11).text_color(t.dim).child("Esc")),
      )
      .when(!this.edit, (el) => el.child(div().text_size(12).text_color(t.muted).child("Backs up the session, stops Claude and closes the pane. Resume it from the Backlog tab.")))
      .child(field("Title", this.title))
      .child(field("Note", this.note))
      .when(Boolean(this.error), (el) =>
        el.child(
          v_flex()
            .gap(3)
            .p(8)
            .rounded(7)
            .bg(t.blocked + "1f")
            .text_size(12)
            .child(div().text_color(t.blocked).child(this.error))
            .children(this.reasons.map((r) => div().truncate().text_color(t.muted).child(`• ${r}`))),
        ),
      )
      .child(div().flex_1())
      .child(
        h_flex()
          .justify_end()
          .gap(8)
          .text_size(12)
          .child(button("cancel", "Cancel", false, () => this.dismiss()))
          .child(button("ok", this.working ? (this.edit ? "Saving…" : "Archiving…") : this.edit ? "Save" : "Archive", true, (cx) => this.submit(cx))),
      );
  }
}
