# claude-as

`claude-as` starts an interactive `claude` as one of several Claude accounts.
Each account has its own `accounts/<email>/` dir, used as `CLAUDE_CONFIG_DIR`.
The tool only sets up config. It never logs in: when an account has no
credentials it prints the login command for that account's dir.

Script: `commands/claude-as` (a single-file `uv run --script`, deps `pyyaml`
and `rich`).

## Setup

`./install` (dotbot) links `~/.local/bin/claude-as` to `commands/claude-as`.
Other tools it calls:

- `claude-custom` (in `commands/`) on `PATH`, required to launch
- `fzf` for the pickers (without it, the account picker falls back to a
  numbered menu)
- `rg` for `search --grep`
- `tg-notify` for reminders (optional, see [Reminders](#reminders))

### Data dir

Accounts and config sit in one data dir, found in this order:

1. `$CLAUDE_AS_HOME`
2. the `~/.config/claude-as/home` symlink (resolved)

With neither set, every command except `--help` exits with an error. The
symlink also covers the systemd units installed by `remind --install`, which do
not inherit your shell env.

```bash
mkdir -p ~/.config/claude-as && ln -s ~/claude-as-data ~/.config/claude-as/home
```

Layout:

```
<data dir>/
  config.yaml
  accounts/
    work@example.com/      # CLAUDE_CONFIG_DIR for that account
    home@example.com/
    default -> work@example.com
```

`config.yaml`:

```yaml
users:                     # label: email
  Work: work@example.com
  Home: home@example.com
# Also accepted: a list of emails or {email, label} maps.

# Accounts an agent orchestrator may fail over to when one reaches its rate
# limit, in order of preference. Selectors as below. Optional.
orchestrate_pool:
  - Work
  - home@example
```

Account dirs are created on first launch. To log an account in:

```bash
CLAUDE_CONFIG_DIR=<data dir>/accounts/work@example.com claude auth login --claudeai --email work@example.com
```

### macOS

Linux keeps an account's tokens in `<dir>/.credentials.json`. On macOS claude
keeps them in the login Keychain instead: a generic password with account
`$USER` and service `Claude Code-credentials-<h>`, where `<h>` is the first 8
hex chars of `sha256(CLAUDE_CONFIG_DIR)`. The hash is over the path string as
given, without resolving symlinks. claude only reads `.credentials.json` when
there is no Keychain item, and deletes the file on its next write. So on
macOS an account counts as logged in when either one exists.

```bash
# which Keychain item an account dir uses
python3 -c 'import hashlib,sys;print("Claude Code-credentials-"+hashlib.sha256(sys.argv[1].encode()).hexdigest()[:8])' "<data dir>/accounts/work@example.com"
```

Other macOS differences: running sessions are found with `ps` and `sysctl
KERN_PROCARGS2` instead of `/proc`, and reminders use launchd instead of
systemd (see [Reminders](#reminders)).

## Launching

```bash
claude-as                          # pick an account (fzf, else a numbered menu)
claude-as work@example.com         # launch as that account
claude-as -- --resume              # pick, then pass --resume to claude
claude-as Work -- --resume         # launch as that account, pass --resume
claude-as accounts [--json]        # email, label, creds, in_pool, default
```

A selector matches an exact email, an exact label, or a unique
case-insensitive substring of either. Everything after `--` goes to `claude`
unchanged, so claude flags need the `--` separator.

On each launch it:

1. Symlinks the shared config layers into the account dir (`settings.base.json`,
   `settings.local.json`, `settings.host.json`, `skills/`, `themes/`,
   `plugins/`, `CLAUDE.md`, `CLAUDE.local.md`, `RTK.md`), each to
   `realpath(~/.claude/<x>)`. It never replaces a regular file or dir, fixes a
   wrong symlink and skips a missing source. `hooks/` is not linked (settings
   reference it as `$HOME/.claude/hooks/...`). A `~/.claude` entry that is in
   neither the link list nor the skip list prints an "unclassified entry"
   warning.
2. Symlinks work and history state (`projects/`, `sessions/`,
   `history.jsonl`, ...) to `~/.claude`, so history and `--resume` are shared
   by all accounts. A per-account copy found there is backed up first as
   `<name>.bak-per-account`.
3. Sets `hasCompletedOnboarding: true` in the account's `.claude.json` so the
   TUI skips its first-run wizard.
4. Stops with the login command if the account has no `.credentials.json`
   (and, on macOS, no Keychain item).
5. On macOS, when `default` points at this account, syncs the two Keychain
   items (see [Default account](#default-account)).
6. Execs `claude-custom`, which regenerates `settings.json` from the linked
   base and local layers and execs claude.

`accounts --json` also lists the resolved `orchestrate_pool`. Selectors that
do not resolve, or resolve to `default`, warn on stderr and are skipped.

## Default account

`accounts/default` is a symlink to one account dir. `claude-as default` passes
the symlink path itself as `CLAUDE_CONFIG_DIR`. Claude re-reads
`.credentials.json` and `.claude.json` through that path on every request, so
flipping the symlink switches running sessions to the other account on their
next API call, without a restart. Background shells keep running.

```bash
claude-as set-default Work         # needs credentials in that account
claude-as get-default              # current default, or "none"
claude-as default -- --resume      # launch through the symlink
```

`set-default` first links shared state into every configured account dir,
then takes the current target's `.oauth_refresh.lock` (claude's mkdir lock,
stale after 60s, gives up after about 70s) and renames a new relative symlink
over `default`. It refuses to touch a `default` that is a regular dir, and
prints how many running sessions use `default`. `default` is never an account
and never in `orchestrate_pool`.

On macOS the symlink alone moves nothing, because the `default` path gets its
own Keychain item (see [macOS](#macos)). claude-as keeps that item in step with
the account it points at:

- `set-default`, under the same lock and before flipping the symlink:
  1. If the `default` item holds newer tokens than its owner's item, it
     copies them back to the owner. The owner is recorded in
     `<data dir>/.default-keychain-owner`.
  2. It writes the new target's tokens into the `default` item.
- On every launch, through `default` or directly, while `default` points at
  that account, claude-as copies the newer of the two items over the other.

"Newer" means a later `claudeAiOauth.expiresAt`. Running default sessions
re-read the Keychain and switch within about 30s.

## Finding and resuming sessions

```bash
claude-as search                       # fzf over all sessions, newest first
claude-as search --as Work infra       # prefill query "infra", resume as Work
claude-as search --grep terraform      # only transcripts containing "terraform"
claude-as search --list | head         # plain table
claude-as search --json                # index rows for scripts
claude-as search -- --model opus       # extra claude args after --
claude-as search --view reminders      # start in the reminders view
claude-as resume 3f2a --as Work -- --model opus   # by id or unique prefix
```

Rows show age, title (`/rename` title, else AI title, else first prompt),
project dir and branch. The query also matches the first and last prompt and
the session id. Picking a row `cd`s into the session's dir (or warns and stays
put) and runs `claude --resume <id>` as `--as <sel>`, or as `default` without
`--as`. `resume <id>` does the same without the picker. A running session is
not resumed a second time (two writers on one transcript) unless you pass
`--force-resume`.

`--grep` is a case-insensitive fixed-string `rg` over the top-level
transcripts. With `--list` and `--json`, query words filter rows by substring.
The index is cached in `~/.cache/claude-as/sessions.json`; only changed
transcripts are parsed again.

Row markers: `🟢<status>` running, `📌` protected, `↩` recently unprotected,
`🗄` archived only (claude deleted the transcript), `⚠` dir gone.

fzf keys:

| key | action |
|---|---|
| `^j` / `^k` | down / up |
| `^s` | cycle view: all, active, protected, unprotected |
| `^p` | protect or unprotect the row (on a `↩` row: undo) |
| `^n` | protect with a note typed on the terminal (Enter saves, Esc cancels) |
| `^r` | reminders view, and back |
| `^a` / `^x` / `^z` | reminders view: ack, cancel, snooze 1h |

`--view all|active|protected|unprotected|reminders` picks the starting view and
filters `--list` and `--json` the same way. In the reminders view, missed
reminders come first, then pending ones, soonest first. Enter resumes the
reminder's session without acking it. A reminder with no session (or one gone
from the index) prints its dir with a `cd` hint and exits 1. `--view
reminders` does not combine with `--grep`.

### Protected sessions

Claude deletes transcripts older than `cleanupPeriodDays`. Protected sessions
are copied to `~/.local/share/claude-as/protected/` (transcript, per-session
dir, every account's `file-history/<id>`) on each launch and search; only
changed files are copied. Resuming one after claude deleted it restores the
copy first.

```bash
claude-as protect 3f2a --note "infra design"   # id or unique prefix
claude-as protect --project ~/work/tf          # that dir and everything below
claude-as protect --list
claude-as unprotect 3f2a                       # keeps the archived copy
claude-as unprotect --project ~/work/tf --purge
claude-as protect --undo [3f2a|<path>]         # re-protect the last unprotected
```

Flags are stored in `~/.local/share/claude-as/protected.json`. Each unprotect
is remembered there (newest 50, at most 30 days) with its note and date, and
`protect --undo` restores both. A copy removed by `--purge` is archived again
from the live transcript when one exists.

## Reminders

```bash
claude-as remind add --in 3h check the deploy      # 30m, 2d, 2w, 1d12h
claude-as remind add --at "2026-11-06 09:30" retro # or HH:MM (today/tomorrow)
claude-as remind list [--missed|--all] [--json]
claude-as remind ack 4be1c2                        # or --all
claude-as remind snooze 4be1c2 1h
claude-as remind rm 4be1c2
claude-as remind digest [--force]                  # missed-reminder digest now
claude-as remind --install                         # systemd timer + listener
claude-as remind --uninstall
```

`add` ties the reminder to `$CLAUDE_CODE_SESSION_ID` (or `--session`) and
protects that session unless `--no-protect`. `remind dispatch`, run every
minute by `claude-as-remind.timer`, sends due reminders through `tg-notify`
with the note, `repo@branch` and `claude-as resume <id>`. A failed send stays
pending and is retried the next minute.

A fired reminder stays missed until acked (`remind ack`, `^a`, or the
Telegram button). Resuming its session does not ack it. `snooze` makes any
reminder pending again; `rm` cancels pending ones.

Each message has `✅ Ack`, `⏰ +1h` and `⏰ +1d` buttons. `remind listen`, run
by `claude-as-remind-listen.service`, long-polls Telegram for presses and
applies them within about a second. Once a reminder is acked, snoozed or
cancelled, its buttons become one status button. Telegram errors print a
warning and never fail the command. Listener logs: `journalctl --user -u
claude-as-remind-listen`.

Once a week, on the first `dispatch` after Monday 09:00 local, a digest lists
every missed reminder with one `✅ Ack all` button. Nothing missed means no
digest.

State files in `~/.local/share/claude-as/`: `reminders.json` (missed ones are
kept; acked and cancelled ones are pruned after 30 days) and `tg-state.json`
(poll offset, chat id, digest state).

`remind --install` writes `claude-as-remind.{service,timer}` and
`claude-as-remind-listen.service` to `~/.config/systemd/user`, with
`ExecStart` set to the `claude-as` found on `PATH`, enables them and restarts
the listener. `--uninstall` stops and removes them.

On macOS, `remind --install` writes launchd agents to `~/Library/LaunchAgents`
instead of systemd units:

- `com.claude-as.remind.plist` runs `dispatch` every 60s and at load.
- `com.claude-as.remind-listen.plist` runs `listen` and is restarted 10s after
  a failed exit.

Both are loaded with `launchctl bootstrap gui/<uid>` and log to
`~/Library/Logs/claude-as/`. `--uninstall` boots them out and removes the
plists.

Without `tg-notify`, `dispatch` marks due reminders as fired with
`last_error` `tg-notify not found`, so they show as missed, and skips the
digest. With a `tg-notify` that lacks `--reply-markup`, `--print-id` or
`--api`, messages go out as plain text without buttons, and `remind
--install` installs only the dispatch timer.

## Tests

From the repo root:

```bash
uv run --with pytest --with rich --with pyyaml pytest tests/ -q
```

Each test runs with `CLAUDE_AS_HOME` set to its own temp dir.

## Known gaps / TODO

### Cross-account resume: background work does not follow the session

Resuming a conversation under another account works: `projects/`,
`sessions/`, `history.jsonl`, `todos/`, `tasks/` and `shell-snapshots/` are
shared, and transcripts contain no account identity. The prompt cache is per
org, so the first turn after switching is a full cache miss billed to the new
account.

Background sessions (daemon jobs): `jobs/` and `daemon*` are in the skip list,
so a job started as account A is invisible from account B. They have to stay
per account: `daemon.lock` and `daemon.status.json` contain host process
identity, `daemon/auth/` and the worker auth in `daemon/roster.json` are
credentials, and `jobs/<short>/state.json` refers to A's daemon. The
conversation can still be resumed in the foreground from B; the live job
handle is lost. A worker blocked on its session limit needs failover most and
loses its handle. Open question: can B list A's jobs read-only (a per-account
job index in a shared path) without sharing auth?

Background shells (`run_in_background`): plain children of the claude
process, killed with it. The transcript records only a task id, and the
output buffer path uses a per-run id, so nothing shared can find it. The
shared `shell-snapshots/` let a resumed session re-run the command with the
same env; it cannot reattach.

| | survives claude exit | reattachable after cross-account resume |
|---|---|---|
| background shell | no, killed with parent | n/a |
| background session (daemon job) | yes, separate supervisor | no, A's daemon and socket auth |

Until this is solved: launch sessions that may need failover with
`claude-as default` and switch with `set-default`, which restarts nothing.
Daemon jobs still stay with the account dir they started under. When a
session launched as a specific account is resumed under another one, start
anything long-lived it ran (dev server, `tail -f`, build) again. To make a
process outlive the session, start it outside claude (`systemd-run --user`,
`tmux`, a herdr pane).

A live session shares its account's `.credentials.json` with any other tool
that refreshes tokens in that dir. A refresh-token race is possible, rare, and
fixed by the next refresh; there is no locking.

macOS: while `default` points at an account, its `default` item and its own
item start with the same refresh token. Copies are made only at launch and
at `set-default`. If a direct session and a `default` session both refresh
before the next sync, one of them may hit a rotated refresh token and need
`/login`. To avoid that, use either `claude-as default` or `claude-as
<account>` for a given account, not both at once.
