// The Backlog tab: Claude sessions put away with the archive button on an
// Agents row (mods/backlog-archive), on every machine, to resume later.
// Lives as the only pane of a tab in the local "Backlog" space (mods/backlog-open).
//
// Each machine keeps its own backlog (`claude-as backlog`, docs/claude-as.md);
// this lists them all: grouped by machine, then repo (the space it was archived
// from, else its folder), newest first. Resume / Edit / Delete per row; Delete
// and Resume move an entry to the bin, where it stays 7 days (Restore, or
// Delete now). An offline machine shows its last known list, greyed.
// Reloads every minute, on Refresh, and when shared "backlog.rev" changes.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { exec, machines, spaces, run, theme, notify, openOverlay, shared, checking } from "herdr";

// hc runs commands without a login shell: put claude-as (~/.local/bin), uv and
// claude-custom on PATH. Keep in step with backlog-archive.
const PATHS = 'PATH="$HOME/.local/bin:$HOME/.dotfiles/commands:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"';
const CLAUDE_AS = `${PATHS} exec claude-as "$@"`;
// In the resumed tab: claude-as execs claude; if it fails, keep the message up.
const RESUME = `${PATHS}; claude-as backlog resume "$1" || { printf '\\nclaude-as backlog resume failed. Press Enter to close. '; read _; }`;
const BIN_DAYS = 7;
const POLL_MS = 60000;
const ICON = "mods/workspace-chrome";

async function claudeAs(args, on) {
  const r = await exec("sh", ["-c", CLAUDE_AS, "sh", ...args], { on: on ?? null, timeout: 60000 });
  const line = r.stdout.trim().split("\n").filter(Boolean).pop() ?? "";
  try {
    return JSON.parse(line);
  } catch {
    throw new Error([r.stdout, r.stderr].map((s) => s.trim()).filter(Boolean).join("\n").slice(-600) || `claude-as exited ${r.code}`);
  }
}

const keyOf = (m) => m ?? "";
const nameOf = (m) => m ?? "This computer";
const base = (p) => (p ?? "").replace(/\/+$/, "").split("/").pop() || p || "?";
const repoOf = (e) => e.meta?.space_name || base(e.cwd);
const ts = (iso) => (iso ? Date.parse(iso) || 0 : 0);

function ago(ms) {
  const m = Math.floor(Math.max(0, ms) / 60000);
  if (m < 1) return "now";
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h`;
  const d = Math.floor(h / 24);
  return d < 60 ? `${d}d` : `${Math.floor(d / 30)}mo`;
}

export default class Backlog extends View {
  init(_props, cx) {
    this.lists = {}; // machine key -> {state: loading|ok|error|offline, entries, bin, error, at}
    try {
      for (const [k, v] of Object.entries(JSON.parse(localStorage.getItem("cache") ?? "{}"))) this.lists[k] = { ...v, state: "cached" };
    } catch {}
    this.folded = new Set(JSON.parse(localStorage.getItem("folded") ?? '["bin"]'));
    this.hovered = null;
    this.confirm = null; // "purge:<machine>:<id>" armed for a second click
    this.pending = new Set(); // rows with an action in flight
    this.rev = shared("backlog.rev") ?? null;
    this.filter = "";
    this.input = InputState.new({ placeholder: "Filter: title, note, repo, branch, machine…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value().trim().toLowerCase();
      cx.notify();
    });
    if (checking()) return;
    this.refresh(cx);
    cx.timer.every(POLL_MS, (cx) => this.refresh(cx));
  }

  machineList() {
    const ms = machines();
    const names = ms.length ? ms.map((m) => m.name) : [null];
    if (!names.includes(null)) names.unshift(null);
    for (const k of Object.keys(this.lists)) if (!names.includes(k || null)) names.push(k || null);
    return names.sort((a, b) => (a === null ? -1 : b === null ? 1 : a.localeCompare(b)));
  }

  available(m) {
    return machines().find((x) => x.name === m)?.layout !== "unavailable";
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.notify();
    cx.spawn(async (cx) => {
      await Promise.all(
        this.machineList().map(async (m) => {
          const k = keyOf(m);
          const prev = this.lists[k] ?? { entries: [], bin: [] };
          if (!this.available(m)) {
            this.lists[k] = { ...prev, state: "offline" };
            return;
          }
          try {
            const out = await claudeAs(["backlog", "list", "--json"], m);
            if (!out.ok) throw new Error(out.error);
            this.lists[k] = { state: "ok", entries: out.entries ?? [], bin: out.bin ?? [], at: Date.now() };
          } catch (e) {
            const error = String(e?.message ?? e);
            // An older claude-as has no `backlog` (it reads it as an account
            // selector); one that isn't there at all says so.
            const why = /unknown option|expected at most one account/i.test(error) ? "outdated" : /not found|No such file/i.test(error) ? "missing" : "error";
            this.lists[k] = { ...prev, state: "error", why, error };
          }
        }),
      );
      const cache = {};
      for (const [k, v] of Object.entries(this.lists)) if (v.state === "ok") cache[k] = { entries: v.entries, bin: v.bin, at: v.at };
      localStorage.setItem("cache", JSON.stringify(cache));
      this.loading = false;
      cx.notify();
    });
  }

  // Runs one claude-as backlog command for a row, then reloads.
  act(cx, m, e, args, done) {
    const key = `${keyOf(m)}:${e.id}`;
    if (this.pending.has(key)) return;
    this.pending.add(key);
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        const out = await claudeAs(["backlog", ...args], m);
        if (!out.ok) throw new Error(out.error);
        if (done) notify({ title: "Backlog", body: done, level: "success", timeout: 2500 });
      } catch (err) {
        notify({ title: "Backlog", body: String(err?.message ?? err), level: "error", timeout: 6000 });
      }
      this.pending.delete(key);
      this.refresh(cx);
    });
  }

  // Q6: the space it came from, else a space on its machine at its folder (or
  // the repo above it), else a new space there.
  resume(cx, m, e) {
    if (e.active) {
      notify({ title: "Backlog", body: `${e.title} is already running${e.active_status ? ` (${e.active_status})` : ""}.`, level: "warning", timeout: 5000 });
      return;
    }
    const argv = ["sh", "-c", RESUME, "sh", e.id];
    const name = (e.title || e.id.slice(0, 8)).slice(0, 40);
    const here = spaces().filter((s) => (s.machine ?? null) === m && !(s.machine === null && s.name === "Backlog"));
    const cwd = e.cwd || "";
    const space =
      spaces().find((s) => s.id === e.meta?.space) ??
      here.find((s) => s.folder && s.folder === cwd) ??
      here.filter((s) => s.folder && cwd.startsWith(s.folder.replace(/\/+$/, "") + "/")).sort((a, b) => b.folder.length - a.folder.length)[0];
    const folder = e.cwd_exists ? cwd : space?.folder || undefined;
    if (space) run("tab.new", { space: space.id, name, folder, argv });
    else run("space.new", { machine: m ?? "", folder, tab: name, argv });
    if (!e.cwd_exists) notify({ title: "Backlog", body: `${cwd || "Its folder"} is gone; resuming from the nearest folder that's left.`, level: "warning", timeout: 6000 });
    // claude-as moves the entry to the bin just before claude starts.
    cx.timer.after(4000, (cx) => this.refresh(cx));
  }

  edit(m, e) {
    openOverlay({ mod: "backlog-archive", kind: "dialog", width: 480, height: 300, props: { edit: true, machine: m, id: e.id, title: e.title, note: e.note ?? "" } });
  }

  toggle(cx, id) {
    this.folded.has(id) ? this.folded.delete(id) : this.folded.add(id);
    localStorage.setItem("folded", JSON.stringify([...this.folded]));
    cx.notify();
  }

  matches(m, e) {
    if (!this.filter) return true;
    return [e.title, e.note, e.cwd, e.branch, repoOf(e), nameOf(m), e.last_prompt, e.first_prompt, e.id].join("\n").toLowerCase().includes(this.filter);
  }

  // ---------------------------------------------------------------- render

  render(cx) {
    const rev = shared("backlog.rev") ?? null;
    if (rev !== this.rev) {
      this.rev = rev;
      if (!checking()) cx.timer.after(0, (cx) => this.refresh(cx));
    }
    const t = theme();
    const now = Date.now();
    const groups = this.machineList().map((m) => {
      const l = this.lists[keyOf(m)] ?? { state: "loading", entries: [], bin: [] };
      return { m, l, entries: (l.entries ?? []).filter((e) => this.matches(m, e)), bin: (l.bin ?? []).filter((e) => this.matches(m, e)) };
    });
    const total = groups.reduce((n, g) => n + g.entries.length, 0);
    const binned = groups.flatMap((g) => g.bin.map((e) => ({ m: g.m, e, live: g.l.state === "ok" }))).sort((a, b) => ts(b.e.binned_at) - ts(a.e.binned_at));

    const iconButton = (id, icon, tip, onClick, color) =>
      div().id(id).p(4).rounded(5).flex_none().text_color(color ?? t.dim).cursor_pointer().hover((s) => s.bg(t.hover).text_color(t.foreground)).tooltip(tip)
        .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
        .child(svg(`${ICON}/${icon}.svg`).size(14));
    const textButton = (id, label, onClick, strong) =>
      h_flex().id(id).h(24).px(9).flex_none().items_center().rounded(6).text_size(11.5)
        .border_1().border_color(strong ? t.solid : t.input).bg(strong ? t.solid : t.raised).text_color(strong ? t.solid_foreground : t.foreground)
        .cursor_pointer().hover((s) => s.opacity(0.88))
        .on_click((_e, cx) => { cx.stop_propagation(); onClick(cx); })
        .child(label);
    const chip = (text, color) => div().flex_none().px(6).h(18).rounded(5).bg(t.raised).text_size(10.5).text_color(color ?? t.muted).flex().items_center().max_w(180).truncate().child(text);

    const row = (m, e, live) => {
      const key = `${keyOf(m)}:${e.id}`;
      const hot = this.hovered === key;
      const busy = this.pending.has(key);
      const last = e.last_prompt || e.first_prompt || "";
      return v_flex()
        .id(`row-${key}`)
        .px(12)
        .py(8)
        .gap(3)
        .rounded(8)
        .when(!live, (el) => el.opacity(0.55))
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = key;
          else if (this.hovered === key) this.hovered = null;
          cx.notify();
        })
        .child(
          h_flex().gap(8).items_center().min_w(0)
            .child(div().flex_1().min_w(0).truncate().font_semibold().text_color(t.foreground).child(e.title || e.id.slice(0, 8)))
            .when(Boolean(e.branch), (el) => el.child(h_flex().gap(3).items_center().flex_none().child(svg(`${ICON}/git-branch.svg`).size(11).text_color(t.dim)).child(chip(e.branch))))
            .when(e.active, (el) => el.child(chip(`running${e.active_status ? ` · ${e.active_status}` : ""}`, t.working)))
            .when(!e.cwd_exists && live, (el) => el.child(chip("folder gone", t.blocked)))
            .when(busy, (el) => el.child(svg(`${ICON}/spinner.svg`).size(12).flex_none().text_color(t.working).spin(900)))
            .when(live && hot && !busy, (el) =>
              el.child(textButton(`resume-${key}`, "Resume", (cx) => this.resume(cx, m, e), true))
                .child(iconButton(`edit-${key}`, "square-pen", "Edit title and note", () => this.edit(m, e)))
                .child(iconButton(`del-${key}`, "x", "Delete (to the bin for 7 days)", (cx) => this.act(cx, m, e, ["bin", e.id], `Moved “${e.title}” to the bin`))))
            .when(!(live && hot) || busy, (el) => el.child(div().flex_none().w(36).text_right().text_size(11).text_color(t.dim).child(ago(now - ts(e.archived_at))))),
        )
        .when(Boolean(e.note), (el) => el.child(div().truncate().text_size(12).text_color(t.muted).italic().child(e.note)))
        .child(
          h_flex().gap(6).min_w(0).text_size(11.5).text_color(t.dim)
            .child(div().flex_none().max_w(260).truncate().child((e.cwd || "").replace(/^\/(Users|home)\/[^/]+/, "~")))
            .when(Boolean(last), (el) => el.child(div().flex_1().min_w(0).truncate().child(`· ${last}`))),
        );
    };

    const binRow = ({ m, e, live }) => {
      const key = `${keyOf(m)}:${e.id}`;
      const hot = this.hovered === `bin:${key}`;
      const busy = this.pending.has(key);
      const left = Math.max(0, BIN_DAYS - Math.floor((now - ts(e.binned_at)) / 86400000));
      const armed = this.confirm === `purge:${key}`;
      return h_flex()
        .id(`bin-${key}`)
        .px(12)
        .h(32)
        .gap(8)
        .items_center()
        .rounded(8)
        .when(!live, (el) => el.opacity(0.55))
        .hover((s) => s.bg(t.hover))
        .on_hover((on, cx) => {
          if (on) this.hovered = `bin:${key}`;
          else if (this.hovered === `bin:${key}`) this.hovered = null;
          if (!on && armed) this.confirm = null;
          cx.notify();
        })
        .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child(e.title || e.id.slice(0, 8)))
        .child(div().flex_none().text_size(11).text_color(t.dim).child(`${nameOf(m)} · ${e.reason ?? "deleted"} · ${left}d left`))
        .when(busy, (el) => el.child(svg(`${ICON}/spinner.svg`).size(12).flex_none().text_color(t.working).spin(900)))
        .when(live && hot && !busy, (el) =>
          el.child(textButton(`restore-${key}`, "Restore", (cx) => this.act(cx, m, e, ["restore", e.id], `Restored “${e.title}”`)))
            .child(textButton(`purge-${key}`, armed ? "Really delete?" : "Delete now", (cx) => {
              if (!armed) {
                this.confirm = `purge:${key}`;
                cx.notify();
                return;
              }
              this.confirm = null;
              this.act(cx, m, e, ["purge", e.id], `Deleted “${e.title}”`);
            }, armed)),
        );
    };

    const header = (id, icon, label, count, extra, strong) => {
      const open = !this.folded.has(id);
      return h_flex()
        .id(`h-${id}`)
        .px(8)
        .pt(strong ? 14 : 8)
        .pb(4)
        .gap(7)
        .items_center()
        .text_size(strong ? 12 : 11.5)
        .when(strong, (el) => el.font_semibold())
        .when(!strong, (el) => el.font_medium())
        .text_color(strong ? t.muted : t.dim)
        .cursor_pointer()
        .hover((s) => s.text_color(t.foreground))
        .on_click((_e, cx) => this.toggle(cx, id))
        .child(svg(`${ICON}/chevron-${open ? "down" : "right"}.svg`).size(11).flex_none())
        .when(Boolean(icon), (el) => el.child(svg(`${ICON}/${icon}.svg`).size(13).flex_none()))
        .child(div().truncate().child(label))
        .child(div().text_color(t.dim).child(String(count)))
        .children(extra ?? []);
    };

    const sections = [];
    for (const g of groups) {
      const live = g.l.state === "ok";
      if (!g.entries.length && live && g.m !== null) continue; // quiet: an empty remote
      const id = `m:${keyOf(g.m)}`;
      const problem = { outdated: "claude-as there has no backlog yet: git pull ~/.dotfiles on that machine", missing: "claude-as isn't installed there: pull ~/.dotfiles and run ./install" }[g.l.why];
      const status =
        g.l.state === "offline" ? [chip("offline", t.dim)]
        : g.l.state === "error" ? [div().id(`err-${id}`).tooltip(g.l.error ?? "").child(chip(g.l.why === "outdated" ? "claude-as outdated" : g.l.why === "missing" ? "no claude-as" : "unreachable", t.blocked))]
        : g.l.state === "loading" || g.l.state === "cached" ? [svg(`${ICON}/spinner.svg`).size(11).flex_none().text_color(t.dim).spin(900)]
        : [];
      sections.push(header(id, g.m === null ? "monitor" : "server", nameOf(g.m), g.entries.length, status, true));
      if (this.folded.has(id)) continue;
      if (!g.entries.length) {
        const msg = g.l.state === "error" ? (problem ?? g.l.error ?? "Couldn't read its backlog.") : this.filter ? "Nothing matches." : "Nothing in the backlog. Archive an agent from its row in Agents.";
        sections.push(div().px(28).py(6).text_size(12).text_color(t.dim).truncate().child(msg));
        continue;
      }
      const repos = new Map();
      for (const e of [...g.entries].sort((a, b) => ts(b.archived_at) - ts(a.archived_at))) {
        const r = repoOf(e);
        if (!repos.has(r)) repos.set(r, []);
        repos.get(r).push(e);
      }
      for (const [r, list] of repos) {
        const rid = `${id}/${r}`;
        sections.push(div().pl(14).child(header(rid, "folder", r, list.length)));
        if (!this.folded.has(rid)) sections.push(v_flex().pl(22).gap(1).children(list.map((e) => row(g.m, e, live))));
      }
    }
    if (binned.length) {
      sections.push(div().h(1).mx(8).mt(14).bg(t.border));
      sections.push(header("bin", "archive", `Bin · purged after ${BIN_DAYS} days`, binned.length, [], false));
      if (!this.folded.has("bin")) sections.push(v_flex().pl(14).gap(1).children(binned.map(binRow)));
    }

    return v_flex()
      .id("backlog")
      .size_full()
      .min_h(0)
      .bg(t.background)
      .text_color(t.foreground)
      .text_size(13)
      .child(
        h_flex()
          .flex_none()
          .px(20)
          .pt(16)
          .pb(10)
          .gap(12)
          .items_center()
          .child(svg(`${ICON}/archive.svg`).size(18).text_color(t.muted))
          .child(div().text_size(17).font_semibold().child("Backlog"))
          .child(div().text_size(12).text_color(t.dim).child(`${total} session${total === 1 ? "" : "s"}`))
          .child(div().flex_1())
          .child(
            h_flex().w(340).h(32).px(10).gap(8).items_center().rounded(8).border_1().border_color(t.input).bg(t.surface)
              .child(svg(`${ICON}/search.svg`).size(14).text_color(t.dim))
              .child(Input.new(this.input).flex_1().h_full().text_size(12.5).text_color(t.foreground)),
          )
          .child(
            this.loading
              ? div().p(4).child(svg(`${ICON}/spinner.svg`).size(14).text_color(t.dim).spin(900))
              : iconButton("refresh", "clock", "Reload every machine's backlog", (cx) => this.refresh(cx)),
          ),
      )
      .child(div().flex_none().h(1).bg(t.border))
      .child(v_flex().id("backlog-list").flex_1().min_h(0).px(12).pb(16).overflow_y_scrollbar().children(sections));
  }
}
