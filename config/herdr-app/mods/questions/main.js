// Question panel: answer an agent's question rounds (e.g. /grilling) in a pane
// beside it, then push the answers back to it in one batch.
//
// The agent posts a round with `herdr-ask` (commands/herdr-ask), which stores
// it as JSON in its own terminal's `questions.round` label. terminals() is
// live, so a new round shows up without polling, for agents on other machines
// too. "Push to agent" pastes every answered, unsent question of the round
// into the agent with `hc send <address>`, as one message.
//
// Opened beside the agent (keys.json: pane.split {mod: "questions"}). The
// target is picked once, from the tab the panel opened in: the terminal with a
// round, else an agent, preferring the focused one. Rounds, drafts and what was
// sent live in shared("questions") by terminal address, so closing and
// reopening the panel loses nothing.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, TextView, Textarea, TextareaState } from "gpui-base";
import { terminals, panes, focused, theme, shared, setShared, hc, notify, nextCommand, run } from "herdr";

const LABEL = "questions.round";
const DISCUSS_LABEL = "questions.discuss"; // on a Discuss fork: {target, round, qid}
const WRAP_UP = "Wrap up: post the discussion summary for the main session now (herdr-ask --discussion), as your instructions say.";
const STORE = "questions";
const KEEP_ROUNDS = 12;
const NOTES = "#notes"; // input key for the round's free-form notes, beside the question ids

// What a Discuss fork is told (it already has the main session's context).
const forkSystemPrompt = (q) =>
  `You are a side fork of the main Claude session, opened from the user's herdr question panel so they can dig into one question (${q.id}${q.title ? `: ${q.title}` : ""}) before answering it. ` +
  `The main session is waiting and won't see this conversation; only your summary goes back. ` +
  `This is a DISCUSSION-ONLY session: explain, compare options, answer follow-ups, and read files or run read-only commands if it helps. ` +
  `Make no changes of any kind: don't edit or create files, don't commit, don't run commands that modify anything, and don't post question rounds (no herdr-ask except --discussion below). ` +
  `If the user asks for a change, say it belongs in the main session and include it in the summary instead. ` +
  `When the user asks you to wrap up, write a short summary for the main session (what was clarified, any decision or leaning the user stated, open concerns; a few bullet lines, no preamble) and post it with:\n` +
  `herdr-ask --discussion ${q.id} <<'EOF'\n<summary>\nEOF\n` +
  `(use ~/.dotfiles/commands/herdr-ask if herdr-ask isn't on PATH). Then stop: this session ends once the summary is posted.`;
// The fork's first message, sent at launch.
const forkFirstPrompt = (q) =>
  `[Side discussion from the question panel: ${q.id}${q.title ? ` (${q.title})` : ""}. This is a discussion-only fork: don't change anything.] ` +
  `I want to understand this question before answering it. Briefly lay out what it hinges on and the trade-offs, then wait for my questions.`;
// Hard stop on file edits; the system prompt covers the rest.
const FORK_DENIED_TOOLS = ["Edit", "Write", "NotebookEdit"];
const machineOf = (address) => (address.includes("/") ? address.slice(0, address.indexOf("/")) : null);

function discussOf(term) {
  try {
    return JSON.parse(term?.labels?.[DISCUSS_LABEL] ?? "null");
  } catch {
    return null;
  }
}

function roundOf(term) {
  const raw = term?.labels?.[LABEL];
  if (!raw) return null;
  try {
    const r = JSON.parse(raw);
    return r && r.id && Array.isArray(r.questions) ? r : null;
  } catch {
    return null;
  }
}

const termByAddress = (address) => terminals().find((t) => t.address === address) ?? null;
const answered = (a) => Boolean(a && (a.accept || (a.text ?? "").trim()));
const answerText = (a) => {
  const text = (a.text ?? "").trim();
  if (a.accept && text) return `yes. ${text}`;
  return a.accept ? "yes" : text;
};

export default class Questions extends View {
  init(props, cx) {
    this.handle = cx.focus_handle();
    // questions-toggle passes the agent it opened beside; otherwise it's picked
    // from the tab on first sync.
    this.target = props?.target ? { address: props.target } : null;
    this.inputs = new Map(); // `${round}:${qid}` -> TextareaState
    this.inputRound = null;
    this.dirty = false;
    this.pushing = false;
    this.syncing = false;
    this.open = new Set(); // expanded earlier rounds
    this.summarizing = new Set(); // fork addresses asked to wrap up
    this.collected = new Set(); // fork addresses whose summary was taken
    cx.timer.every(2000, () => this.flush());
    cx.timer.every(600, (cx) => this.collectDiscussions(cx));
    this.pendingShow = null; // {address, until}: a fork to give a pane once the app sees it
    cx.timer.every(150, (cx) => this.showPending(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "focus") this.handle.focus();
        else if (c === "push") this.push(cx);
        cx.notify();
      }
    });
  }

  // ---------------------------------------------------------------- target

  pickTarget() {
    const f = focused();
    if (!f?.tab) return null;
    const inTab = panes().filter((p) => p.tab === f.tab && p.terminal);
    const score = (p) => (roundOf(termByAddress(p.terminal)) ? 4 : 0) + (p.status ? 2 : 0) + (p.terminal === f.terminal ? 1 : 0);
    const best = inTab.sort((a, b) => score(b) - score(a))[0];
    return best ? { address: best.terminal } : null;
  }

  retarget() {
    this.flush();
    this.target = this.pickTarget();
    this.inputRound = null; // rebuild inputs for the new target's round
  }

  // ---------------------------------------------------------------- store

  history() {
    const all = shared(STORE) ?? {};
    return this.target ? all[this.target.address]?.rounds ?? [] : [];
  }

  saveHistory(rounds) {
    const all = { ...(shared(STORE) ?? {}) };
    all[this.target.address] = { rounds: rounds.slice(-KEEP_ROUNDS) };
    // Drop entries for terminals that no longer exist.
    const live = new Set(terminals().map((t) => t.address));
    for (const k of Object.keys(all)) if (!live.has(k)) delete all[k];
    setShared(STORE, all);
  }

  // Copies typed drafts into the store. Typing only touches memory (a shared
  // write re-renders every mod), so this runs on a timer, blur and push.
  flush() {
    if (!this.dirty || !this.target) return;
    this.dirty = false;
    const rounds = this.history().map((r) => ({ ...r, answers: { ...(r.answers ?? {}) } }));
    for (const [key, state] of this.inputs) {
      const [rid, qid] = splitKey(key);
      const r = rounds.find((x) => x.id === rid);
      if (!r) continue;
      if (qid === NOTES) r.notes = state.value();
      else if (!r.answers[qid]?.sent) r.answers[qid] = { ...(r.answers[qid] ?? {}), text: state.value() };
    }
    this.saveHistory(rounds);
  }

  // ---------------------------------------------------------------- sync

  // Live data is empty until the first render, and retained text state can't
  // be made during render, so render schedules this on a timer when needed.
  // (Not cx.spawn: TextareaState.new throws inside a spawned task.)
  needsSync() {
    if (panes().length === 0) return false;
    if (!this.target || !termByAddress(this.target.address)) return !this.target;
    const live = roundOf(termByAddress(this.target.address));
    if (live && !this.history().some((r) => r.id === live.id)) return true;
    const current = this.currentRound();
    if (!current) return false;
    return this.inputRound !== current.id || Object.values(current.answers ?? {}).some((a) => a?.inbox?.length);
  }

  sync() {
    if (!this.target) this.retarget();
    if (!this.target) return;
    const live = roundOf(termByAddress(this.target.address));
    let rounds = this.history();
    if (live && !rounds.some((r) => r.id === live.id)) {
      this.flush();
      rounds = [...this.history(), { id: live.id, topic: live.topic ?? "", at: Date.now(), questions: live.questions, session: live.session ?? null, cwd: live.cwd ?? null, answers: {} }];
      this.saveHistory(rounds);
    }
    const current = this.currentRound();
    if (current && this.inputRound !== current.id) this.makeInputs(current);
    if (current) this.takeInbox(current);
  }

  // Discussion summaries collectDiscussions() left on a question go to
  // the end of its answer box, where they can be edited before Push.
  takeInbox(round) {
    const waiting = round.questions.filter((q) => round.answers?.[q.id]?.inbox?.length);
    if (!waiting.length) return;
    this.flush();
    const rounds = this.history().map((r) => {
      if (r.id !== round.id) return r;
      const answers = { ...(r.answers ?? {}) };
      for (const q of waiting) {
        const { inbox = [], ...a } = answers[q.id] ?? {};
        const s = this.inputs.get(`${r.id}:${q.id}`);
        const before = (s ? s.value() : a.text ?? "").trimEnd();
        const added = inbox.map((summary) => `Discussion summary:\n${summary.trim()}`).join("\n\n");
        a.text = before ? `${before}\n\n${added}` : added;
        s?.set_value(a.text);
        answers[q.id] = a;
      }
      return { ...r, answers };
    });
    this.saveHistory(rounds);
  }

  makeInputs(round) {
    for (const s of this.inputs.values()) s.release();
    this.inputs.clear();
    this.inputRound = round.id;
    const add = (key, placeholder, value) => {
      const s = TextareaState.new({ placeholder, value });
      s.set_auto_grow(2, 10);
      s.on("change", (_e, cx) => {
        this.dirty = true;
        cx.notify();
      });
      s.on("blur", () => this.flush());
      this.inputs.set(`${round.id}:${key}`, s);
    };
    for (const q of round.questions) {
      const a = round.answers?.[q.id];
      if (a?.sent) continue;
      add(q.id, q.recommended ? "Your answer, or leave empty and Accept" : "Your answer", a?.text ?? "");
    }
    add(NOTES, "Anything else to tell the agent (sent with the answers)", round.notes ?? "");
  }

  notesText(round) {
    const s = this.inputs.get(`${round.id}:${NOTES}`);
    return (s ? s.value() : round.notes ?? "").trim();
  }

  // The round the agent's label shows now, else nothing: once it clears the
  // label (or the panel lost its agent), every round is history.
  currentRound() {
    if (!this.target) return null;
    const live = roundOf(termByAddress(this.target.address));
    return live ? this.history().find((r) => r.id === live.id) ?? null : null;
  }

  // ---------------------------------------------------------------- actions

  draft(round, qid) {
    const a = { ...(round.answers?.[qid] ?? {}) };
    const s = this.inputs.get(`${round.id}:${qid}`);
    if (s) a.text = s.value();
    return a;
  }

  toggleAccept(round, qid) {
    this.flush();
    const rounds = this.history().map((r) => {
      if (r.id !== round.id) return r;
      const a = { ...(r.answers?.[qid] ?? {}) };
      a.accept = !a.accept;
      return { ...r, answers: { ...(r.answers ?? {}), [qid]: a } };
    });
    this.saveHistory(rounds);
  }

  push(cx) {
    const round = this.currentRound();
    if (!round || this.pushing) return;
    const ready = round.questions.filter((q) => {
      const a = this.draft(round, q.id);
      return !a.sent && answered(a);
    });
    const notes = this.notesText(round);
    if (ready.length === 0 && !notes) {
      notify({ title: "Questions", body: "Nothing new to push", level: "warning", timeout: 2500 });
      return;
    }
    const open = round.questions.filter((q) => {
      const a = this.draft(round, q.id);
      return !a.sent && !answered(a);
    });
    const lines = [`Answers from the question panel${round.topic ? ` (${round.topic})` : ""}:`, ""];
    for (const q of ready) {
      const body = answerText(this.draft(round, q.id)).replace(/\n/g, "\n   ");
      lines.push(`${q.id}${q.title ? ` (${q.title})` : ""}: ${body}`);
    }
    if (notes) lines.push(...(ready.length ? [""] : []), "Notes:", notes);
    if (open.length) lines.push("", `Still open: ${open.map((q) => q.id).join(", ")}`);

    const address = this.target.address;
    this.pushing = true;
    this.flush();
    cx.spawn(async (cx) => {
      let error = null;
      try {
        const r = await hc(["send", address, lines.join("\n")]);
        if (r.code !== 0) error = (r.stderr || r.stdout || `hc send exited ${r.code}`).trim();
      } catch (e) {
        error = String(e);
      }
      this.pushing = false;
      if (error) {
        notify({ title: "Push failed", body: error, level: "error", timeout: 6000 });
      } else {
        const sent = new Set(ready.map((q) => q.id));
        const rounds = this.history().map((r) => {
          if (r.id !== round.id) return r;
          const answers = { ...(r.answers ?? {}) };
          for (const q of r.questions) {
            if (!sent.has(q.id)) continue;
            answers[q.id] = { ...this.draft(r, q.id), sent: true };
            this.inputs.get(`${r.id}:${q.id}`)?.release();
            this.inputs.delete(`${r.id}:${q.id}`);
          }
          if (!notes) return { ...r, answers };
          this.inputs.get(`${r.id}:${NOTES}`)?.set_value("");
          return { ...r, answers, notes: "", sentNotes: [...(r.sentNotes ?? []), notes] };
        });
        this.saveHistory(rounds);
        const what = [ready.length ? `${ready.length} answer${ready.length === 1 ? "" : "s"}` : "", notes ? "notes" : ""].filter(Boolean).join(" + ");
        notify({ title: "Questions", body: `Pushed ${what}`, level: "success", timeout: 2000 });
      }
      cx.notify();
    });
  }

  // The live Discuss fork for this question, if one is running.
  forkFor(round, qid) {
    return terminals().find((t) => {
      const d = discussOf(t);
      return d && d.target === this.target?.address && d.round === round.id && d.qid === qid;
    }) ?? null;
  }

  // Shows a fork in a pane below this panel (in the agent's tab), or focuses
  // the pane it already has.
  showFork(address) {
    if (panes().some((p) => p.terminal === address)) return run("pane.focus", { terminal: address });
    const tab = panes().find((p) => p.terminal === this.target?.address)?.tab;
    const panel = panes().find((p) => p.mod === "questions" && p.tab === tab);
    if (panel) run("pane.focus", { pane: panel.pane });
    run("terminal.keep", { terminal: address, place: "down" });
  }

  showPending(cx) {
    const p = this.pendingShow;
    if (!p) return;
    if (terminals().some((t) => t.address === p.address)) {
      this.pendingShow = null;
      this.showFork(p.address);
      cx.notify();
    } else if (Date.now() > p.until) {
      this.pendingShow = null;
      notify({ title: "Discuss", body: `Started ${p.address}, but it never showed up here; use Show on the card to retry.`, level: "warning", timeout: 6000 });
      cx.notify();
    }
  }

  // Done: ask the fork to post its summary; collectDiscussions() takes it from there.
  wrapUp(cx, address) {
    if (this.summarizing.has(address)) return;
    this.summarizing.add(address);
    cx.spawn(async (cx) => {
      const r = await hc(["send", address, WRAP_UP]).catch((e) => ({ code: 1, stderr: String(e) }));
      if (r.code !== 0) {
        this.summarizing.delete(address);
        notify({ title: "Discussion", body: (r.stderr || r.stdout || "hc send failed").trim(), level: "error", timeout: 6000 });
      }
      cx.notify();
    });
  }

  // Close: end the fork without a summary (--rm takes its pane with it).
  endFork(cx, address) {
    this.summarizing.delete(address);
    cx.spawn(async () => {
      await hc(["kill", address]).catch(() => null);
    });
  }

  // A fork that posted its summary (herdr-ask --discussion): put it in that
  // question's inbox (sync() appends it to the answer box) and end the fork.
  // Runs on a timer, so a summary posted while the panel was closed is picked
  // up when it opens.
  collectDiscussions(cx) {
    if (!this.target) return;
    for (const t of terminals()) {
      const d = discussOf(t);
      const raw = t.labels?.["questions.discussion"];
      if (!d || !raw || d.target !== this.target.address || this.collected.has(t.address)) continue;
      let posted;
      try {
        posted = JSON.parse(raw);
      } catch {
        continue;
      }
      if (!posted?.summary) continue;
      const rounds = this.history();
      if (!rounds.some((r) => r.id === d.round)) continue;
      this.collected.add(t.address);
      this.summarizing.delete(t.address);
      this.saveHistory(
        rounds.map((r) => {
          if (r.id !== d.round) return r;
          const a = { ...(r.answers?.[d.qid] ?? {}) };
          a.inbox = [...(a.inbox ?? []), posted.summary];
          return { ...r, answers: { ...(r.answers ?? {}), [d.qid]: a } };
        }),
      );
      notify({ title: "Discussion", body: `Summary added to ${d.qid}'s answer box; edit it there, then Push`, level: "success", timeout: 3000 });
      this.endFork(cx, t.address);
      cx.notify();
    }
  }

  // Forks the agent's Claude session on its machine, in its folder, and shows
  // the fork in a pane below the panel. The main session is untouched.
  discuss(cx, round, q) {
    const running = this.forkFor(round, q.id);
    if (running) return this.showFork(running.address);
    // The agent's label is the source of truth; the stored copy may predate these fields.
    const live = roundOf(termByAddress(this.target.address));
    if (live?.id === round.id) round = { ...round, session: live.session ?? round.session, cwd: live.cwd ?? round.cwd };
    if (!round.session) {
      notify({ title: "Discuss", body: "This round has no Claude session id (posted by an older herdr-ask, or not from Claude Code).", level: "warning", timeout: 5000 });
      return;
    }
    if (this.launching) return;
    this.launching = true;
    const on = machineOf(this.target.address);
    const tag = JSON.stringify({ target: this.target.address, round: round.id, qid: q.id });
    // --rm: once killed it's gone, and its pane with it.
    const args = ["run", "--bg", "--json", "--no-parent", "--rm", ...(on ? ["--on", on] : []), ...(round.cwd ? ["--cwd", round.cwd] : []), "--label", `${DISCUSS_LABEL}=${tag}`, "--"];
    // The prompt goes first: --disallowedTools/--allowedTools take every value after them.
    const argv = ["claude", forkFirstPrompt(q), "--resume", round.session, "--fork-session", "--append-system-prompt", forkSystemPrompt(q), "--disallowedTools", ...FORK_DENIED_TOOLS, "--allowedTools", "Bash(herdr-ask --discussion:*)", "Bash(~/.dotfiles/commands/herdr-ask --discussion:*)"];
    cx.spawn(async (cx) => {
      try {
        const r = await hc([...args, ...argv]);
        const out = JSON.parse(r.stdout || "{}");
        if (r.code !== 0 || !out.address) throw new Error(out.error?.message || r.stderr || r.stdout || `hc run exited ${r.code}`);
        // Remote runs answer with machine/tN already; local ones with a bare id.
        // The app hears of the new terminal a moment later; terminal.keep fails
        // until then, so showPending() waits for it.
        this.pendingShow = { address: out.address, until: Date.now() + 10000 };
      } catch (e) {
        notify({ title: "Discuss failed", body: String(e?.message ?? e).trim(), level: "error", timeout: 8000 });
      }
      this.launching = false;
      cx.notify();
    });
  }

  // ---------------------------------------------------------------- render

  render(cx) {
    if (this.needsSync() && !this.syncing) {
      this.syncing = true;
      cx.timer.after(0, (cx) => {
        this.syncing = false;
        try {
          this.sync();
        } catch (e) {
          notify({ title: "Questions: sync failed", body: `${e?.message ?? e}`, level: "error", timeout: 15000 });
        }
        cx.notify();
      });
    }

    const t = theme();
    const term = this.target ? termByAddress(this.target.address) : null;
    const pane = this.target ? panes().find((p) => p.terminal === this.target.address) : null;
    const current = this.currentRound();
    const earlier = this.history().filter((r) => r !== current && r.id !== current?.id).reverse();

    const root = v_flex()
      .id("questions")
      .track_focus(this.handle)
      .size_full()
      .min_h(0)
      .bg(t.surface)
      .text_color(t.foreground)
      .text_size(13);

    // Header: who the panel answers.
    const who = pane?.program?.name || term?.foreground?.name || "agent";
    root.child(
      h_flex()
        .flex_none()
        .items_center()
        .gap(8)
        .px(14)
        .py(10)
        .border_b(1)
        .border_color(t.border)
        .child(div().text_size(14).font_semibold().child("Questions"))
        .child(div().flex_1().min_w(0).truncate().text_size(11.5).text_color(t.dim).child(this.target ? `${who} · ${this.target.address}` : "no agent"))
        .child(this.smallButton(t, "q-retarget", "Retarget", () => this.retarget())),
    );

    if (!this.target || !term) {
      return root.child(this.empty(t, this.target ? "That agent is gone. Focus an agent in this tab, then Retarget." : "No terminal in this tab yet. Focus an agent, then Retarget."));
    }

    const body = v_flex().id("q-scroll").flex_1().min_h(0).overflow_y_scrollbar().p(12).gap(12);
    if (current) {
      body.child(this.roundHeader(t, current, true));
      body.children(current.questions.map((q) => this.card(t, current, q)));
      body.child(this.notesCard(t, current));
    } else body.child(this.empty(t, "No open round. The agent posts one with herdr-ask."));

    if (earlier.length) {
      body.child(div().pt(8).text_size(11).font_semibold().text_color(t.dim).child("EARLIER ROUNDS"));
      for (const r of earlier) {
        body.child(this.roundHeader(t, r, false));
        if (!this.open.has(r.id)) continue;
        body.children(r.questions.map((q) => this.card(t, r, q, true)));
        if (r.sentNotes?.length) body.child(this.notesCard(t, r, true));
      }
    }
    root.child(body);

    if (current) root.child(this.footer(t, current));
    return root;
  }

  empty(t, text) {
    return div().p(16).text_size(12.5).text_color(t.muted).child(text);
  }

  roundHeader(t, r, isCurrent) {
    const total = r.questions.length;
    const sent = r.questions.filter((q) => r.answers?.[q.id]?.sent).length;
    const label = `${r.topic || "Round"} · ${sent}/${total} sent`;
    if (isCurrent) return div().text_size(11.5).text_color(t.dim).child(label);
    const open = this.open.has(r.id);
    return h_flex()
      .id(`q-round-${r.id}`)
      .gap(6)
      .items_center()
      .px(8)
      .py(6)
      .rounded(6)
      .cursor_pointer()
      .text_size(12)
      .text_color(t.muted)
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => {
        if (open) this.open.delete(r.id);
        else this.open.add(r.id);
        cx.notify();
      })
      .child(open ? "▾" : "▸")
      .child(div().flex_1().min_w(0).truncate().child(label))
      .child(div().text_size(11).text_color(t.dim).child(new Date(r.at).toLocaleTimeString()));
  }

  card(t, round, q, readonly = false) {
    const a = this.draft(round, q.id);
    const state = a.sent ? "sent" : answered(a) ? "ready" : "open";
    const chip = { sent: [t.raised, t.dim, "✓ sent"], ready: [t.accent, t.accent_foreground, "ready"], open: [t.raised, t.muted, "open"] }[state];
    const input = this.inputs.get(`${round.id}:${q.id}`);
    const key = `${round.id}-${q.id}`;
    const live = !a.sent && !readonly && this.currentRound()?.id === round.id;
    const fork = live ? this.forkFor(round, q.id) : null;

    const card = v_flex()
      .id(`q-card-${key}`)
      .gap(8)
      .p(12)
      .rounded(10)
      .border_1()
      .border_color(state === "ready" ? t.accent : t.border)
      .bg(t.background)
      .when(state === "sent", (el) => el.opacity(0.75))
      .child(
        h_flex()
          .items_center()
          .gap(8)
          .child(div().flex_none().px(6).py(1).rounded(5).bg(t.raised).text_size(11.5).font_semibold().child(q.id))
          .child(div().flex_1().min_w(0).font_semibold().child(q.title ?? ""))
          .when(live && !fork, (el) => el.child(this.smallButton(t, `q-discuss-${key}`, this.launching ? "Starting…" : "Discuss", (cx) => this.discuss(cx, round, q), "Talk it through in a fork of the agent's session, in a pane below")))
          .when(Boolean(fork), (el) =>
            this.summarizing.has(fork.address)
              ? el.child(div().flex_none().text_size(11).text_color(t.dim).child("summarizing…"))
              : el
                  .child(this.smallButton(t, `q-show-${key}`, "Show", () => this.showFork(fork.address), "Focus the discussion pane"))
                  .child(this.smallButton(t, `q-done-${key}`, "Done", (cx) => this.wrapUp(cx, fork.address), `Summarize the discussion into ${q.id}'s answer box (edit it there before Push), then end the fork`))
                  .child(this.smallButton(t, `q-close-${key}`, "Close", (cx) => this.endFork(cx, fork.address), "End the discussion without a summary")),
          )
          .child(div().flex_none().px(7).py(1).rounded(9).bg(chip[0]).text_color(chip[1]).text_size(10.5).child(chip[2])),
      );

    if (q.body) card.child(div().text_size(12.5).text_color(t.muted).child(TextView.markdown(`q-body-${key}`, q.body).selectable(true)));

    if (q.recommended) {
      const accepted = Boolean(a.accept);
      const canToggle = !a.sent && !readonly && this.currentRound()?.id === round.id;
      const rec = h_flex()
        .gap(8)
        .items_start()
        .p(8)
        .rounded(8)
        .bg(t.raised)
        .child(div().flex_none().child("➡️"))
        .child(div().flex_1().min_w(0).text_size(12.5).child(TextView.markdown(`q-rec-${key}`, q.recommended).selectable(true)));
      if (canToggle)
        rec.child(
          h_flex()
            .id(`q-accept-${key}`)
            .flex_none()
            .h(26)
            .px(10)
            .items_center()
            .rounded(7)
            .border_1()
            .border_color(accepted ? t.solid : t.input)
            .bg(accepted ? t.solid : t.background)
            .text_color(accepted ? t.solid_foreground : t.foreground)
            .text_size(11.5)
            .font_medium()
            .cursor_pointer()
            .hover((s) => s.opacity(0.88))
            .on_click((_e, cx) => {
              this.toggleAccept(round, q.id);
              cx.notify();
            })
            .child(accepted ? "✓ Accepted" : "Accept"),
        );
      else if (accepted) rec.child(div().flex_none().text_size(11.5).text_color(t.dim).child("✓ accepted"));
      card.child(rec);
    }


    if (input && !readonly) {
      card.child(Textarea.new(input).w_full().px(10).py(8).rounded(8).border_1().border_color(t.input).bg(t.surface).text_size(12.5).text_color(t.foreground));
    } else if (answered(a)) {
      card.child(div().px(10).py(8).rounded(8).bg(t.surface).text_size(12.5).child(answerText(a)));
    }
    return card;
  }

  // Free-form notes for the round: pushed with the answers (or alone), then
  // cleared; what was sent stays listed above the box.
  notesCard(t, round, readonly = false) {
    const input = this.inputs.get(`${round.id}:${NOTES}`);
    const card = v_flex()
      .id(`q-notes-${round.id}`)
      .gap(8)
      .p(12)
      .rounded(10)
      .border_1()
      .border_color(!readonly && this.notesText(round) ? t.accent : t.border)
      .bg(t.background)
      .child(div().font_semibold().child("Notes"));
    for (const [i, n] of (round.sentNotes ?? []).entries())
      card.child(div().id(`q-sent-note-${round.id}-${i}`).px(10).py(8).rounded(8).bg(t.surface).text_size(12.5).opacity(0.75).child(`✓ ${n}`));
    if (input && !readonly) card.child(Textarea.new(input).w_full().px(10).py(8).rounded(8).border_1().border_color(t.input).bg(t.surface).text_size(12.5).text_color(t.foreground));
    return card;
  }

  footer(t, round) {
    const ready = round.questions.filter((q) => {
      const a = this.draft(round, q.id);
      return !a.sent && answered(a);
    }).length;
    const open = round.questions.filter((q) => !this.draft(round, q.id).sent).length;
    const notes = Boolean(this.notesText(round));
    const enabled = (ready > 0 || notes) && !this.pushing;
    return h_flex()
      .flex_none()
      .items_center()
      .gap(10)
      .px(14)
      .py(10)
      .border_t(1)
      .border_color(t.border)
      .child(div().flex_1().text_size(11.5).text_color(t.dim).child(`${ready} ready · ${open - ready} open${notes ? " · notes" : ""}`))
      .child(
        h_flex()
          .id("q-push")
          .h(32)
          .px(14)
          .items_center()
          .rounded(8)
          .border_1()
          .border_color(enabled ? t.solid : t.input)
          .bg(enabled ? t.solid : t.raised)
          .text_color(enabled ? t.solid_foreground : t.dim)
          .text_size(12.5)
          .font_medium()
          .when(enabled, (el) => el.cursor_pointer().hover((s) => s.opacity(0.88)))
          .on_click((_e, cx) => {
            if (enabled) this.push(cx);
            cx.notify();
          })
          .child(this.pushing ? "Pushing…" : ready ? `Push ${ready}${notes ? " + notes" : ""} to agent` : notes ? "Push notes to agent" : "Push to agent"),
      );
  }

  smallButton(t, id, label, action, tip = null) {
    return h_flex()
      .id(id)
      .when(Boolean(tip), (el) => el.tooltip(tip))
      .flex_none()
      .h(24)
      .px(8)
      .items_center()
      .rounded(6)
      .text_size(11)
      .text_color(t.muted)
      .cursor_pointer()
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => {
        action(cx);
        cx.notify();
      })
      .child(label);
  }

  async close() {
    this.flush();
  }
}

function splitKey(key) {
  const i = key.lastIndexOf(":");
  return [key.slice(0, i), key.slice(i + 1)];
}
