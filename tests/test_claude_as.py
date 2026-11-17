"""Tests for claude-as filesystem logic (default symlink, OAuth lock, /proc scan)."""
import importlib.machinery
import importlib.util
import json
import os
import pty
import select
import subprocess
import time
from pathlib import Path

import pytest

# claude-as has no .py extension: load it with an explicit SourceFileLoader.
_path = Path(__file__).resolve().parent.parent / "commands" / "claude-as"
_loader = importlib.machinery.SourceFileLoader("claude_as", str(_path))
_spec = importlib.util.spec_from_loader("claude_as", _loader)
ca = importlib.util.module_from_spec(_spec)
_loader.exec_module(ca)


@pytest.fixture(autouse=True)
def as_home(tmp_path, monkeypatch):
    """Every test gets tmp_path as its claude-as data dir."""
    monkeypatch.setenv("CLAUDE_AS_HOME", str(tmp_path))
    return tmp_path


def _write_config(users, **extra):
    """Write config.yaml (as JSON, a YAML subset) into the data dir."""
    cfg = {"users": [{"email": e, "label": l} if l else e for e, l in users], **extra}
    (ca.as_home() / "config.yaml").write_text(json.dumps(cfg))


@pytest.fixture
def accounts(tmp_path):
    d = tmp_path / "accounts"
    for email in ("a@x.org", "b@x.org"):
        (d / email).mkdir(parents=True)
    return d


# --- flip_default / current_default ----------------------------------------

def test_flip_creates_relative_symlink(accounts):
    ca.flip_default("a@x.org")
    link = accounts / "default"
    assert link.is_symlink()
    assert os.readlink(link) == "a@x.org"
    assert ca.current_default() == "a@x.org"


def test_flip_replaces_existing_symlink(accounts):
    ca.flip_default("a@x.org")
    ca.flip_default("b@x.org")
    link = accounts / "default"
    assert os.readlink(link) == "b@x.org"
    assert link.resolve() == (accounts / "b@x.org").resolve()
    # No tmp link left behind.
    assert sorted(p.name for p in accounts.iterdir()) == ["a@x.org", "b@x.org", "default"]


def test_flip_uses_rename_over_default(accounts, monkeypatch):
    calls = []
    real_replace = os.replace

    def spy(src, dst):
        calls.append((Path(src).name, Path(dst).name))
        return real_replace(src, dst)

    monkeypatch.setattr(ca.os, "replace", spy)
    ca.flip_default("a@x.org")
    assert calls == [(f"default.tmp-{os.getpid()}", "default")]


def test_flip_refuses_real_dir(accounts):
    (accounts / "default").mkdir()
    (accounts / "default" / "keep").write_text("x")
    with pytest.raises(ca.DefaultError):
        ca.flip_default("a@x.org")
    assert (accounts / "default" / "keep").read_text() == "x"
    with pytest.raises(ca.DefaultError):
        ca.current_default()


def test_flip_refuses_missing_account_dir(accounts):
    with pytest.raises(ca.DefaultError):
        ca.flip_default("nope@x.org")
    assert not (accounts / "default").is_symlink()


def test_current_default_none(accounts):
    assert ca.current_default() is None


# --- oauth_refresh_lock ----------------------------------------------------

def test_lock_acquire_and_release(tmp_path):
    lock = tmp_path / ca.OAUTH_LOCK_NAME
    with ca.oauth_refresh_lock(tmp_path) as held:
        assert held == lock
        assert lock.is_dir()
    assert not lock.exists()


def test_lock_released_on_error(tmp_path):
    with pytest.raises(RuntimeError):
        with ca.oauth_refresh_lock(tmp_path):
            raise RuntimeError("boom")
    assert not (tmp_path / ca.OAUTH_LOCK_NAME).exists()


def test_lock_takes_over_stale(tmp_path):
    lock = tmp_path / ca.OAUTH_LOCK_NAME
    lock.mkdir()
    old = time.time() - 120
    os.utime(lock, (old, old))
    with ca.oauth_refresh_lock(tmp_path, timeout=1, poll=0.01):
        assert lock.is_dir()
        assert time.time() - lock.stat().st_mtime < 5
    assert not lock.exists()


def test_lock_times_out_when_fresh(tmp_path):
    lock = tmp_path / ca.OAUTH_LOCK_NAME
    lock.mkdir()
    t0 = time.monotonic()
    with pytest.raises(ca.LockTimeout):
        with ca.oauth_refresh_lock(tmp_path, timeout=0.2, poll=0.05):
            pytest.fail("acquired a held lock")
    assert time.monotonic() - t0 >= 0.2
    assert lock.is_dir()  # someone else's lock is left alone


# --- count_default_sessions ------------------------------------------------

def _proc(root: Path, pid: int, ppid: int, env: dict[str, str]) -> None:
    d = root / str(pid)
    d.mkdir(parents=True)
    (d / "environ").write_bytes(
        b"".join(f"{k}={v}".encode() + b"\0" for k, v in env.items()))
    (d / "stat").write_text(f"{pid} (claude (x)) S {ppid} 1 1 0\n")


def test_count_default_sessions(tmp_path):
    proc = tmp_path / "proc"
    want = "/repo/accounts/default"
    _proc(proc, 100, 1, {"CLAUDE_CONFIG_DIR": want, "HOME": "/h"})
    _proc(proc, 101, 100, {"CLAUDE_CONFIG_DIR": want})        # child shell
    _proc(proc, 200, 1, {"CLAUDE_CONFIG_DIR": want + "/"})    # trailing slash
    _proc(proc, 300, 1, {"CLAUDE_CONFIG_DIR": "/repo/accounts/a@x.org"})
    _proc(proc, 400, 1, {"PATH": "/bin"})
    (proc / "self").mkdir()
    (proc / "500").mkdir()                                      # unreadable environ
    assert ca.count_default_sessions(Path(want), proc_root=proc) == 2


def test_count_default_sessions_missing_proc(tmp_path):
    assert ca.count_default_sessions(Path("/x"), proc_root=tmp_path / "nope") == 0


# --- accounts listing / pool -----------------------------------------------

def test_accounts_marks_default_and_skips_symlink(accounts, monkeypatch, capsys):
    _write_config([("a@x.org", "A"), ("b@x.org", None), ("default", "D")],
                  orchestrate_pool=["default", "b@x.org"])
    ca.flip_default("b@x.org")
    assert ca.cmd_accounts(as_json=True) == 0
    out = json.loads(capsys.readouterr().out)
    assert [r["email"] for r in out["accounts"]] == ["a@x.org", "b@x.org"]
    assert [r["default"] for r in out["accounts"]] == [False, True]
    assert set(out["accounts"][0]) == {"email", "label", "creds", "in_pool", "default"}
    assert out["orchestrate_pool"] == ["b@x.org"]


# --- cmd_set_default (isolated CLAUDE_HOME, fake /proc) ---------------------

@pytest.fixture
def set_default_env(accounts, tmp_path, monkeypatch):
    home = tmp_path / "claude-home"
    (home / "projects").mkdir(parents=True)
    monkeypatch.setattr(ca, "CLAUDE_HOME", home)
    _write_config([("a@x.org", "A"), ("b@x.org", "B")])
    monkeypatch.setattr(ca, "count_default_sessions", lambda *a, **k: 0)
    for email in ("a@x.org", "b@x.org"):
        (accounts / email / ".credentials.json").touch()
    return accounts


def test_set_default_flips_under_old_lock(set_default_env, monkeypatch):
    accounts = set_default_env
    locked = []
    real_lock = ca.oauth_refresh_lock

    def spy(cfg, **kw):
        locked.append(cfg)
        return real_lock(cfg, **kw)

    monkeypatch.setattr(ca, "oauth_refresh_lock", spy)
    assert ca.cmd_set_default("A") == 0
    assert locked == []  # no previous default -> nothing to lock
    assert ca.current_default() == "a@x.org"
    # Shared state linked into every configured account dir.
    assert (accounts / "a@x.org" / "projects").is_symlink()
    assert (accounts / "b@x.org" / "projects").is_symlink()

    assert ca.cmd_set_default("b@x") == 0
    assert locked == [accounts / "a@x.org"]
    assert ca.current_default() == "b@x.org"
    assert not (accounts / "a@x.org" / ca.OAUTH_LOCK_NAME).exists()


def test_set_default_noop_and_rejections(set_default_env, capsys):
    accounts = set_default_env
    assert ca.cmd_set_default("default") == 2
    (accounts / "b@x.org" / ".credentials.json").unlink()
    assert ca.cmd_set_default("B") == 1
    assert ca.current_default() is None
    assert ca.cmd_set_default("A") == 0
    capsys.readouterr()
    assert ca.cmd_set_default("A") == 0
    assert "already default" in capsys.readouterr().out


# --- session search ---------------------------------------------------------

def _rec(**kw) -> str:
    return json.dumps(kw, separators=(",", ":"))  # compact, as claude writes


def _user(text, cwd="/w", branch="main", **kw) -> str:
    return _rec(type="user", cwd=cwd, gitBranch=branch, sessionId="s",
                message={"role": "user", "content": text}, **kw)


def _write(path: Path, lines: list[str]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n")
    return path


@pytest.fixture
def search_env(tmp_path, monkeypatch):
    home = tmp_path / "claude-home"
    (home / "projects").mkdir(parents=True)
    monkeypatch.setattr(ca, "CLAUDE_HOME", home)
    monkeypatch.setattr(ca, "SEARCH_CACHE", tmp_path / "cache" / "sessions.json")
    monkeypatch.setattr(ca, "PROTECTED_FILE", tmp_path / "share" / "protected.json")
    monkeypatch.setattr(ca, "PROTECTED_ARCHIVE", tmp_path / "share" / "protected")
    monkeypatch.setattr(ca, "PROC_ROOT", tmp_path / "proc")
    monkeypatch.setattr(ca, "_SYNCED", False)
    return home / "projects"


def test_title_precedence_last_wins(search_env):
    proj = search_env / "-w"
    _write(proj / "a.jsonl", [
        _user("first prompt"),
        _rec(type="ai-title", aiTitle="ai one"),
        _rec(type="custom-title", customTitle="mine one"),
        _rec(type="ai-title", aiTitle="ai two"),
        _rec(type="custom-title", customTitle="mine two"),
        _rec(type="last-prompt", lastPrompt="lp one"),
        _rec(type="last-prompt", lastPrompt="lp two"),
    ])
    _write(proj / "b.jsonl", [_user("hello"), _rec(type="ai-title", aiTitle="ai b1"),
                              _rec(type="ai-title", aiTitle="ai b2")])
    _write(proj / "c.jsonl", [_user("just a prompt")])
    rows = {r["id"]: r for r in ca.session_index()}
    assert rows["a"]["title"] == "mine two"
    assert rows["a"]["ai_title"] == "ai two"
    assert rows["a"]["last_prompt"] == "lp two"
    assert rows["b"]["title"] == "ai b2"
    assert rows["b"]["custom_title"] == ""
    assert rows["c"]["title"] == "just a prompt"


def test_first_prompt_skips_meta_wrappers_and_malformed(search_env):
    _write(search_env / "-w" / "s.jsonl", [
        "{not json",
        "[1, 2]",
        "\"str\"",
        _user("meta text", isMeta=True),
        _user("side text", isSidechain=True),
        _user("<command-name>/clear</command-name>"),
        _user([{"type": "tool_result", "content": "x"}]),
        _user([{"type": "image"}, {"type": "text", "text": "  real\n prompt  "}],
              cwd="/first"),
        _user("second prompt", cwd="/last", branch="feat"),
        "garbage {\"type\":\"ai-title\"",
    ])
    (row,) = ca.session_index()
    assert row["first_prompt"] == "real prompt"
    assert row["title"] == "real prompt"
    assert row["cwd"] == "/last"
    assert row["branch"] == "feat"


def test_first_prompt_truncated(search_env):
    _write(search_env / "-w" / "s.jsonl", [_user("x" * 500)])
    (row,) = ca.session_index()
    assert len(row["first_prompt"]) == ca.FIRST_PROMPT_MAX
    assert row["first_prompt"].endswith("…")


def test_subagent_transcripts_ignored(search_env):
    proj = search_env / "-w"
    _write(proj / "main.jsonl", [_user("top")])
    _write(proj / "main" / "subagents" / "agent-1.jsonl", [_user("sub")])
    assert [r["id"] for r in ca.session_index()] == ["main"]


def test_cwd_exists(search_env, tmp_path):
    real = tmp_path / "realdir"
    real.mkdir()
    _write(search_env / "-a" / "a.jsonl", [_user("a", cwd=str(real))])
    _write(search_env / "-b" / "b.jsonl", [_user("b", cwd=str(tmp_path / "gone"))])
    rows = {r["id"]: r for r in ca.session_index()}
    assert rows["a"]["cwd_exists"] is True
    assert rows["b"]["cwd_exists"] is False


def test_cache_reuse_and_invalidation(search_env, monkeypatch):
    proj = search_env / "-w"
    a = _write(proj / "a.jsonl", [_user("a")])
    b = _write(proj / "b.jsonl", [_user("b")])
    parsed = []
    real_parse = ca.parse_session

    def spy(path):
        parsed.append(path.name)
        return real_parse(path)

    monkeypatch.setattr(ca, "parse_session", spy)
    assert len(ca.session_index()) == 2
    assert sorted(parsed) == ["a.jsonl", "b.jsonl"]
    assert ca.SEARCH_CACHE.exists()

    parsed.clear()
    assert len(ca.session_index()) == 2
    assert parsed == []

    _write(a, [_user("a"), _rec(type="custom-title", customTitle="renamed")])
    b.unlink()
    parsed.clear()
    rows = ca.session_index()
    assert parsed == ["a.jsonl"]
    assert [(r["id"], r["title"]) for r in rows] == [("a", "renamed")]
    cache = json.loads(ca.SEARCH_CACHE.read_text())
    assert list(cache["files"]) == [str(a)]


def test_cache_version_mismatch_rebuilds(search_env, monkeypatch):
    _write(search_env / "-w" / "a.jsonl", [_user("a")])
    ca.session_index()
    cache = json.loads(ca.SEARCH_CACHE.read_text())
    cache["version"] = -1
    ca.SEARCH_CACHE.write_text(json.dumps(cache))
    parsed = []
    monkeypatch.setattr(ca, "parse_session",
                        lambda p, real=ca.parse_session: parsed.append(p) or real(p))
    ca.session_index()
    assert len(parsed) == 1


def test_search_json_shape_and_order(search_env, capsys):
    proj = search_env / "-w"
    old = _write(proj / "old.jsonl", [_user("old one")])
    new = _write(proj / "new.jsonl", [_user("new one")])
    os.utime(old, (1000, 1000))
    os.utime(new, (2000, 2000))
    assert ca.main(["search", "--json"]) == 0
    out = json.loads(capsys.readouterr().out)
    assert [r["id"] for r in out] == ["new", "old"]
    assert set(out[0]) == {"id", "title", "custom_title", "ai_title", "cwd",
                           "cwd_exists", "branch", "mtime", "first_prompt",
                           "last_prompt", "path", "live", "protected", "note",
                           "unprotected_at", "active", "active_status", "active_pid"}
    assert (out[0]["live"], out[0]["protected"], out[0]["active"]) == (True, False, False)
    assert out[0]["unprotected_at"] is None
    assert out[0]["mtime"] == 2000
    assert out[0]["path"] == str(new)

    assert ca.main(["search", "--json", "OLD"]) == 0
    assert [r["id"] for r in json.loads(capsys.readouterr().out)] == ["old"]


def test_search_rejects_bad_args(search_env):
    assert ca.main(["search", "--bogus"]) == 2
    assert ca.main(["search", "--list", "--json"]) == 2
    assert ca.main(["search", "--as"]) == 2
    assert ca.main(["search", "--json", "--as", "x"]) == 2


def test_search_pick_chdirs_and_resumes_default(search_env, tmp_path, monkeypatch):
    work = tmp_path / "work"
    work.mkdir()
    _write(search_env / "-w" / "sid.jsonl", [_user("hi", cwd=str(work))])
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    seen = {}

    def fake_run(cmd, **kw):
        seen["cmd"] = cmd
        seen["input"] = kw["input"]
        return ca.subprocess.CompletedProcess(cmd, 0, stdout="sid\n")

    monkeypatch.setattr(ca.subprocess, "run", fake_run)
    monkeypatch.setattr(ca, "launch_default", lambda args: seen.setdefault("args", args) and 0)
    monkeypatch.chdir(tmp_path)
    assert ca.main(["search", "hi", "there", "--", "--model", "x"]) == 0
    assert seen["args"] == ["--resume", "sid", "--model", "x"]
    assert Path.cwd() == work
    assert "--query=hi there" in seen["cmd"]
    assert seen["input"].split("\t")[0] == "sid"


def test_search_pick_missing_cwd_and_as(search_env, tmp_path, monkeypatch):
    _write(search_env / "-w" / "sid.jsonl", [_user("hi", cwd=str(tmp_path / "gone"))])
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    _write_config([("a@x.org", "A")])
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw:
                        ca.subprocess.CompletedProcess(cmd, 0, stdout="sid\n"))
    launched = []
    monkeypatch.setattr(ca, "launch", lambda email, args: launched.append((email, args)))
    monkeypatch.chdir(tmp_path)
    assert ca.main(["search", "--as", "A"]) == 0
    assert launched == [("a@x.org", ["--resume", "sid"])]
    assert Path.cwd() == tmp_path


def test_search_no_selection_returns_quietly(search_env, monkeypatch):
    _write(search_env / "-w" / "sid.jsonl", [_user("hi")])
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw:
                        ca.subprocess.CompletedProcess(cmd, 130, stdout=""))
    monkeypatch.setattr(ca, "launch_default", lambda args: pytest.fail("launched"))
    assert ca.main(["search"]) == 0


def test_search_fzf_missing(search_env, monkeypatch):
    monkeypatch.setattr(ca.shutil, "which", lambda name: None)
    assert ca.main(["search"]) == 1


def test_search_preview(search_env, capsys):
    _write(search_env / "-w" / "sid.jsonl", [
        _user("first"),
        _rec(type="assistant", message={"role": "assistant", "content": [
            {"type": "thinking", "thinking": "hmm"},
            {"type": "tool_use", "name": "Bash"}]}),
        _rec(type="assistant", message={"role": "assistant", "content": [
            {"type": "text", "text": "answer"}]}),
        _user([{"type": "tool_result", "content": "out"}]),
    ])
    assert ca.main(["search", "--preview", "sid"]) == 0
    out = capsys.readouterr().out
    assert "id:      sid" in out
    assert "[you] first" in out and "[claude] answer" in out
    assert "hmm" not in out and "out" not in out.split("first:")[1]
    assert out.index("[you] first") < out.index("[claude] answer")
    assert ca.main(["search", "--preview", "missing"]) == 1


def test_age():
    assert ca._age(0, now=30) == "30s"
    assert ca._age(0, now=3 * 3600) == "3h"
    assert ca._age(0, now=5 * 86400) == "5d"
    assert ca._age(0, now=65 * 86400) == "2mo"


@pytest.mark.skipif(not ca.shutil.which("rg"), reason="needs ripgrep")
def test_search_grep_filters_top_level(search_env, capsys):
    proj = search_env / "-w"
    _write(proj / "hit.jsonl", [_user("talk about NeedleWord here")])
    _write(proj / "miss.jsonl", [_user("nothing")])
    _write(proj / "miss" / "subagents" / "agent-1.jsonl", [_user("needleword")])
    assert ca.main(["search", "--grep", "needleword", "--json"]) == 0
    assert [r["id"] for r in json.loads(capsys.readouterr().out)] == ["hit"]
    assert ca.main(["search", "--grep", "-x", "--json"]) == 0
    assert json.loads(capsys.readouterr().out) == []


# --- protected sessions -----------------------------------------------------

def _store():
    return json.loads(ca.PROTECTED_FILE.read_text())


def _fake_proc(root: Path, pid: int, start: str, cmdline: bytes = b"claude\0") -> None:
    d = root / str(pid)
    d.mkdir(parents=True)
    (d / "stat").write_text(f"{pid} (cl aude) S " + " ".join(["0"] * 18) + f" {start} 0 0\n")
    (d / "cmdline").write_bytes(cmdline)


def _session_file(home: Path, pid: int, sid: str, **kw) -> None:
    d = home / "sessions"
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{pid}.json").write_text(json.dumps(
        {"pid": pid, "sessionId": sid, "cwd": "/w", "status": "idle", **kw}))


@pytest.fixture
def protect_env(search_env, tmp_path):
    """Live session `abc123` (with a per-session dir) in /w, plus file-history
    for it in account a@x.org; `default` -> a@x.org."""
    proj = search_env / "-w"
    t = _write(proj / "abc123.jsonl", [_user("keep me", cwd="/w")])
    _write(proj / "abc123" / "subagents" / "agent-1.jsonl", [_user("sub")])
    _write(proj / "abd999.jsonl", [_user("other", cwd="/w")])
    acct = ca.accounts_root() / "a@x.org"
    _write(acct / "file-history" / "abc123" / "f@v1", ["v1"])
    os.symlink("a@x.org", ca.accounts_root() / "default")
    return t


def test_protect_by_prefix_and_ambiguous(protect_env, capsys):
    with pytest.raises(SystemExit) as exc:
        ca.main(["protect", "ab"])
    assert exc.value.code == 2
    assert "abc123" in capsys.readouterr().out
    with pytest.raises(SystemExit) as exc:
        ca.main(["protect", "zz"])
    assert exc.value.code == 2
    assert not ca.PROTECTED_FILE.exists()

    assert ca.main(["protect", "abc", "--note", "important"]) == 0
    store = _store()
    assert store["sessions"]["abc123"]["note"] == "important"
    assert store["sessions"]["abc123"]["added"]
    arch = ca.PROTECTED_ARCHIVE
    assert (arch / "projects" / "-w" / "abc123.jsonl").read_bytes() == protect_env.read_bytes()
    assert (arch / "projects" / "-w" / "abc123" / "subagents" / "agent-1.jsonl").exists()
    assert (arch / "file-history" / "a@x.org" / "abc123" / "f@v1").exists()
    assert not (arch / "projects" / "-w" / "abd999.jsonl").exists()
    assert "archived" in capsys.readouterr().out


def test_protect_rejects_bad_args(protect_env):
    assert ca.main(["protect"]) == 2
    assert ca.main(["protect", "abc", "--project", "/w"]) == 2
    assert ca.main(["protect", "--list", "--note", "x"]) == 2
    assert ca.main(["protect", "--note"]) == 2
    assert ca.main(["unprotect", "abc", "--note", "x"]) == 2


def test_project_rule_covers_subdirs_not_sibling_prefix(search_env, tmp_path):
    store = {"sessions": {}, "projects": {"/a/b": {"note": "proj", "added": "x"}}}
    assert ca.protection("s", "/a/b", store) == (True, "proj")
    assert ca.protection("s", "/a/b/c/d", store) == (True, "proj")
    assert ca.protection("s", "/a/bc", store) == (False, None)
    assert ca.protection("s", "", store) == (False, None)

    root = tmp_path / "a" / "b"
    _write(search_env / "-x" / "new.jsonl", [_user("n", cwd=str(root / "sub"))])
    _write(search_env / "-y" / "sib.jsonl", [_user("s", cwd=str(root) + "c")])
    assert ca.main(["protect", "--project", str(root)]) == 0
    assert list(_store()["projects"]) == [str(root)]
    rows = {r["id"]: r for r in ca.session_index()}
    assert rows["new"]["protected"] and not rows["sib"]["protected"]
    assert (ca.PROTECTED_ARCHIVE / "projects" / "-x" / "new.jsonl").exists()
    assert not (ca.PROTECTED_ARCHIVE / "projects" / "-y" / "sib.jsonl").exists()


def test_sync_copies_only_when_changed(protect_env, monkeypatch):
    assert ca.main(["protect", "abc123"]) == 0
    copies = []
    real_copy = ca.shutil.copy2
    monkeypatch.setattr(ca.shutil, "copy2",
                        lambda s, d: copies.append(Path(s).name) or real_copy(s, d))
    assert ca.sync_protected() == {"abc123": 0}
    assert copies == []

    with open(protect_env, "a") as fh:
        fh.write(_user("more") + "\n")
    sub = protect_env.parent / "abc123" / "subagents" / "agent-1.jsonl"
    sub.unlink()
    assert ca.sync_protected() == {"abc123": 1}
    assert copies == ["abc123.jsonl"]
    archived = ca.PROTECTED_ARCHIVE / "projects" / "-w"
    assert (archived / "abc123.jsonl").read_bytes() == protect_env.read_bytes()
    assert (archived / "abc123" / "subagents" / "agent-1.jsonl").exists()  # never deleted
    assert (archived / "abc123.jsonl").stat().st_mtime_ns == protect_env.stat().st_mtime_ns


def test_sync_noop_without_protection(search_env, monkeypatch):
    monkeypatch.setattr(ca, "session_index", lambda **kw: pytest.fail("indexed"))
    assert ca.sync_protected() == {}


def test_archived_only_session_in_index(protect_env, capsys):
    assert ca.main(["protect", "abc123", "--note", "zebra"]) == 0
    protect_env.unlink()
    rows = {r["id"]: r for r in ca.session_index()}
    row = rows["abc123"]
    assert row["live"] is False and row["protected"] is True
    assert row["path"] == str(ca.PROTECTED_ARCHIVE / "projects" / "-w" / "abc123.jsonl")
    assert rows["abd999"]["live"] is True
    capsys.readouterr()
    assert ca.main(["search", "--json", "zebra"]) == 0  # notes are searchable
    assert [r["id"] for r in json.loads(capsys.readouterr().out)] == ["abc123"]
    assert ca.main(["search", "--preview", "abc123"]) == 0
    assert "archived only" in capsys.readouterr().out


def test_live_copy_preferred_over_archive(protect_env):
    assert ca.main(["protect", "abc123"]) == 0
    rows = [r for r in ca.session_index() if r["id"] == "abc123"]
    assert len(rows) == 1 and rows[0]["live"] is True
    assert rows[0]["path"] == str(protect_env)


def _pick(monkeypatch, sid):
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw:
                        ca.subprocess.CompletedProcess(cmd, 0, stdout=f"{sid}\n"))
    launched = []
    monkeypatch.setattr(ca, "launch_default", lambda args: launched.append(args) or 0)
    return launched


def test_restore_on_resume(protect_env, monkeypatch, capsys):
    assert ca.main(["protect", "abc123"]) == 0
    proj = protect_env.parent
    data = protect_env.read_bytes()
    protect_env.unlink()
    ca.shutil.rmtree(proj / "abc123")
    fh = ca.accounts_root() / "a@x.org" / "file-history" / "abc123"
    ca.shutil.rmtree(fh)
    launched = _pick(monkeypatch, "abc123")
    assert ca.main(["search"]) == 0
    assert launched == [["--resume", "abc123"]]
    assert protect_env.read_bytes() == data
    assert (proj / "abc123" / "subagents" / "agent-1.jsonl").exists()
    assert (fh / "f@v1").exists()
    assert "restored from archive" in capsys.readouterr().out


def test_unprotect_keeps_or_purges(protect_env, capsys):
    assert ca.main(["protect", "abc123"]) == 0
    assert ca.main(["unprotect", "abc1"]) == 0
    assert _store()["sessions"] == {}
    assert "kept" in capsys.readouterr().out
    assert (ca.PROTECTED_ARCHIVE / "projects" / "-w" / "abc123.jsonl").exists()
    assert ca.main(["unprotect", "abc1"]) == 1  # no longer protected

    assert ca.main(["protect", "abc123"]) == 0
    assert ca.main(["unprotect", "abc123", "--purge"]) == 0
    assert ca._archived_paths("abc123") == []


def test_unprotect_project_purge(search_env, tmp_path):
    root = tmp_path / "p"
    _write(search_env / "-p" / "s1.jsonl", [_user("x", cwd=str(root / "a"))])
    assert ca.main(["protect", "--project", str(root)]) == 0
    assert ca._archived_paths("s1")
    assert ca.main(["unprotect", "--project", str(tmp_path / "nope")]) == 1
    assert ca.main(["unprotect", "--project", str(root), "--purge"]) == 0
    assert _store()["projects"] == {}
    assert ca._archived_paths("s1") == []


def test_toggle(protect_env):
    assert ca.main(["protect", "--toggle", "abc123"]) == 0
    assert "abc123" in _store()["sessions"]
    assert ca.main(["protect", "--toggle", "abc123"]) == 0
    assert _store()["sessions"] == {}


def test_ask_note(protect_env, monkeypatch):
    monkeypatch.setattr(ca, "_read_tty", lambda prompt: None)
    assert ca.main(["protect", "--ask-note", "abc123"]) == 1
    assert not ca.PROTECTED_FILE.exists()
    monkeypatch.setattr(ca, "_read_tty", lambda prompt: "  my note \n")
    assert ca.main(["protect", "--ask-note", "abc123"]) == 0
    assert _store()["sessions"]["abc123"]["note"] == "my note"


@pytest.mark.parametrize("keys,expected", [
    (b"my note\r", "my note"),
    ("h\u00e9x\x7f\r".encode(), "h\u00e9"),
    (b"\r", ""),
    (b"ab\x15cd\r", "cd"),
    (b"ab\x1b[Ccd\r", "abcd"),
    (b"ab\x1b", None),
    (b"ab\x03", None),
])
def test_read_tty(keys, expected):
    r, w = os.pipe()
    pid, master = pty.fork()
    if pid == 0:
        os.close(r)
        try:
            result = ca._read_tty("note: ")
        except BaseException as exc:  # noqa: BLE001
            result = repr(exc)
        os.write(w, json.dumps(result).encode())
        os._exit(0)
    os.close(w)
    shown, out = b"", b""
    deadline = time.monotonic() + 5
    while b"note: " not in shown and time.monotonic() < deadline:
        if select.select([master], [], [], 0.1)[0]:
            shown += os.read(master, 1024)
    os.write(master, keys)
    while time.monotonic() < deadline:
        if select.select([r], [], [], 0.1)[0]:
            chunk = os.read(r, 1024)
            if not chunk:
                break
            out += chunk
    if not out:
        os.kill(pid, 9)
    os.waitpid(pid, 0)
    os.close(r)
    os.close(master)
    assert out, "child did not return in time"
    assert json.loads(out) == expected


def test_protect_list(protect_env, capsys):
    assert ca.main(["protect", "--list"]) == 0
    assert "no protected" in capsys.readouterr().out
    assert ca.main(["protect", "abc123", "--note", "nn"]) == 0
    assert ca.main(["protect", "--project", "/w"]) == 0
    capsys.readouterr()
    assert ca.main(["protect", "--list"]) == 0
    out = capsys.readouterr().out
    assert "abc123"[:6] in out and "nn" in out and "protected projects" in out


# --- active sessions --------------------------------------------------------

def test_active_sessions_detection(search_env, tmp_path):
    home = ca.CLAUDE_HOME
    proc = ca.PROC_ROOT
    _session_file(home, 10, "live", procStart="555", status="working")
    _fake_proc(proc, 10, "555")
    _session_file(home, 11, "recycled", procStart="1")
    _fake_proc(proc, 11, "999")
    _session_file(home, 12, "dead", procStart="5")
    _session_file(home, 13, "nostart")
    _fake_proc(proc, 13, "0")
    _session_file(home, 14, "notclaude")
    _fake_proc(proc, 14, "0", cmdline=b"bash\0")
    (home / "sessions" / "15.abc.key").write_text("x")
    (home / "sessions" / "x.json").write_text(json.dumps({"pid": 10, "sessionId": "bad"}))
    (home / "sessions" / "16.json").write_text("{broken")
    got = ca.active_sessions()
    assert set(got) == {"live", "nostart"}
    assert got["live"] == {"pid": 10, "status": "working", "cwd": "/w", "name": ""}


def test_active_session_marker_and_refusal(protect_env, monkeypatch, capsys):
    _session_file(ca.CLAUDE_HOME, 42, "abc123", procStart="7", status="working")
    _fake_proc(ca.PROC_ROOT, 42, "7")
    (row,) = [r for r in ca.session_index() if r["id"] == "abc123"]
    assert (row["active"], row["active_status"], row["active_pid"]) == (True, "working", 42)
    assert "🟢working" in ca._fzf_line(row)

    launched = _pick(monkeypatch, "abc123")
    assert ca.main(["search"]) == 1
    assert launched == []
    assert "already running: pid 42, status working" in capsys.readouterr().out
    assert ca.main(["search", "--force-resume"]) == 0
    assert launched == [["--resume", "abc123"]]
    assert ca.main(["search", "--json", "--force-resume"]) == 2


# --- views / fzf ------------------------------------------------------------

def test_views_filter_rows_and_json(protect_env, capsys):
    _session_file(ca.CLAUDE_HOME, 42, "abd999", procStart="7")
    _fake_proc(ca.PROC_ROOT, 42, "7")
    assert ca.main(["protect", "abc123"]) == 0
    capsys.readouterr()

    def ids(*args):
        assert ca.main(["search", *args]) == 0
        out = capsys.readouterr().out
        if "--json" in args:
            return sorted(r["id"] for r in json.loads(out))
        return sorted(line.split("\t")[0] for line in out.splitlines())

    for mode in ("--json", "--rows"):
        assert ids(mode) == ["abc123", "abd999"]
        assert ids(mode, "--view", "all") == ["abc123", "abd999"]
        assert ids(mode, "--view", "active") == ["abd999"]
        assert ids(mode, "--view", "protected") == ["abc123"]
    assert ca.main(["search", "--view", "bogus"]) == 2
    assert ca.main(["search", "--rows", "--json"]) == 2


def test_fzf_line_markers_aligned(protect_env):
    assert ca.main(["protect", "abc123"]) == 0
    protect_env.unlink()
    rows = {r["id"]: r for r in ca.session_index()}
    a, b = (ca._markers(rows[s]) for s in ("abc123", "abd999"))
    assert [ca._cells(x) for x in a] == [ca._cells(x) for x in b] == [9, 2, 1, 1]
    assert a[1:] == ("📌", "🗄", "⚠")
    assert b[1:] == ("  ", " ", "⚠")


def test_fzf_command_binds(search_env):
    cmd = ca._fzf_command("q", "pat")
    binds = [cmd[i + 1] for i, a in enumerate(cmd) if a == "--bind"]
    keys = [b.split(":", 1)[0] for b in binds]
    assert keys == ["ctrl-j", "ctrl-k", "ctrl-s", "ctrl-p", "ctrl-n", "ctrl-r",
                    "ctrl-a", "ctrl-x", "ctrl-z", "start"]
    assert binds[:2] == ["ctrl-j:down", "ctrl-k:up"]
    assert binds[2].startswith("ctrl-s:transform:")
    assert "--prompt=all> " in cmd and "--id-nth=1" in cmd
    assert f"--header={ca.FZF_HEADER}" in cmd and "--header-first" in cmd
    assert "--preview-window=right,50%,wrap" in cmd
    assert all("pat" not in b for b in binds)  # pattern travels via env
    assert all(f'--grep "${ca.GREP_ENV}"' in b for b in binds[2:6])
    assert binds[3].startswith("ctrl-p:track-current+execute-silent(")
    assert "protect --toggle {1}" in binds[3]
    assert binds[4].startswith("ctrl-n:track-current+execute(")
    assert "protect --ask-note {1}" in binds[4]
    assert all('"${FZF_PROMPT%%>*}"' in b for b in binds[3:5])
    assert binds[9] == "start:unbind(ctrl-a,ctrl-x,ctrl-z)"
    script = str(Path(ca.__file__).resolve())
    assert all(script in b for b in binds[2:9])


@pytest.mark.parametrize("header", ["FZF_HEADER", "REMIND_HEADER"])
def test_fzf_header_fits_beside_preview(header):
    # The right-side preview leaves the header half of a 100-column terminal.
    lines = getattr(ca, header).split("\n")
    assert len(lines) == 3
    assert all(ca._cells(line) <= 46 for line in lines)


@pytest.mark.parametrize("prompt,view", [("all> ", "active"),
                                         ("active> ", "protected"),
                                         ("protected> ", "unprotected"),
                                         ("unprotected> ", "all")])
def test_fzf_ctrl_s_cycles_views(search_env, prompt, view):
    cmd = ca._fzf_command("", "pat")
    bind = next(a for a in cmd if a.startswith("ctrl-s:"))
    snippet = bind.removeprefix("ctrl-s:transform:")
    out = subprocess.run(["sh", "-c", snippet], capture_output=True, text=True,
                         env={**os.environ, "FZF_PROMPT": prompt}).stdout
    script = str(Path(ca.__file__).resolve())
    assert out.startswith(f"change-prompt({view}> )+change-header[")
    assert "+rebind(ctrl-p,ctrl-n)+unbind(ctrl-a,ctrl-x,ctrl-z)+reload:" in out
    assert out.endswith(f'search --rows --view {view} --grep "${ca.GREP_ENV}"')
    assert script in out


def test_launch_syncs_before_exec(search_env, tmp_path, monkeypatch):
    acct = ca.accounts_root() / "a@x.org"
    acct.mkdir(parents=True)
    (acct / ".credentials.json").touch()
    monkeypatch.setattr(ca, "account_dir", lambda e: ca.accounts_root() / e)
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    order = []
    monkeypatch.setattr(ca, "sync_protected", lambda rows=None: order.append("sync"))
    monkeypatch.setattr(ca.os, "execve", lambda *a: order.append("exec"))
    ca.launch("a@x.org", [])
    assert order == ["sync", "exec"]


def test_sync_failure_only_warns(search_env, monkeypatch, capsys):
    def boom(rows=None):
        raise RuntimeError("disk on fire")

    monkeypatch.setattr(ca, "sync_protected", boom)
    ca._sync_quietly()
    assert "disk on fire" in capsys.readouterr().err


# --- recently unprotected / undo --------------------------------------------

def _write_store(data: dict) -> None:
    ca.PROTECTED_FILE.parent.mkdir(parents=True, exist_ok=True)
    ca.PROTECTED_FILE.write_text(json.dumps(data))


def _iso(days_ago: float) -> str:
    return ca.datetime.fromtimestamp(time.time() - days_ago * 86400).astimezone() \
        .isoformat(timespec="seconds")


def test_unprotect_records_session_entry(protect_env):
    assert ca.main(["protect", "abc123", "--note", "keep"]) == 0
    added = _store()["sessions"]["abc123"]["added"]
    assert _store()["unprotected"] == []
    assert ca.main(["unprotect", "abc1"]) == 0
    (entry,) = _store()["unprotected"]
    assert entry["kind"] == "session" and entry["id"] == "abc123"
    assert (entry["note"], entry["added"]) == ("keep", added)
    assert ca._iso_ts(entry["removed"]) == pytest.approx(time.time(), abs=5)


def test_unprotect_project_records_entry(search_env, tmp_path):
    root = tmp_path / "p"
    _write(search_env / "-p" / "s1.jsonl", [_user("x", cwd=str(root / "a"))])
    assert ca.main(["protect", "--project", str(root), "--note", "proj"]) == 0
    assert ca.main(["unprotect", "--project", str(root)]) == 0
    (entry,) = _store()["unprotected"]
    assert (entry["kind"], entry["path"], entry["note"]) == ("project", str(root), "proj")
    rows = {r["id"]: r for r in ca.session_index()}
    assert rows["s1"]["unprotected_at"] == entry["removed"]


def test_toggle_off_records_and_toggle_on_restores(protect_env):
    assert ca.main(["protect", "abc123", "--note", "orig"]) == 0
    added = _store()["sessions"]["abc123"]["added"]
    assert ca.main(["protect", "--toggle", "abc123"]) == 0
    assert [e["id"] for e in _store()["unprotected"]] == ["abc123"]
    row = next(r for r in ca.session_index() if r["id"] == "abc123")
    assert row["unprotected_at"] and "↩" in ca._fzf_line(row)
    assert ca._markers(row)[1] == "↩ "
    assert ca.main(["protect", "--toggle", "abc123"]) == 0
    store = _store()
    assert store["sessions"]["abc123"] == {"note": "orig", "added": added}
    assert store["unprotected"] == []


def test_reprotect_with_new_note_drops_entry(protect_env):
    assert ca.main(["protect", "abc123", "--note", "orig"]) == 0
    assert ca.main(["unprotect", "abc123"]) == 0
    assert ca.main(["protect", "abc123", "--note", "fresh"]) == 0
    store = _store()
    assert store["sessions"]["abc123"]["note"] == "fresh"
    assert store["unprotected"] == []


def test_undo_latest_and_by_prefix(protect_env, tmp_path, capsys):
    assert ca.main(["protect", "abc123", "--note", "one"]) == 0
    assert ca.main(["protect", "abd999", "--note", "two"]) == 0
    added = _store()["sessions"]["abc123"]["added"]
    assert ca.main(["unprotect", "abc123"]) == 0
    assert ca.main(["unprotect", "abd999"]) == 0
    assert [e["id"] for e in _store()["unprotected"]] == ["abd999", "abc123"]
    capsys.readouterr()

    assert ca.main(["protect", "--undo"]) == 0
    assert "restored protection" in capsys.readouterr().out
    assert list(_store()["sessions"]) == ["abd999"]
    assert ca.main(["unprotect", "abd999"]) == 0

    assert ca.main(["protect", "--undo", "ab"]) == 2  # ambiguous
    assert ca.main(["protect", "--undo", "abc"]) == 0
    store = _store()
    assert store["sessions"] == {"abc123": {"note": "one", "added": added}}
    assert [e["id"] for e in store["unprotected"]] == ["abd999"]
    assert ca.main(["protect", "--undo", "zzz"]) == 1
    assert ca.main(["protect", "--undo", "a", "b"]) == 2
    assert ca.main(["protect", "--undo", "--note", "x"]) == 2


def test_undo_project_by_path(search_env, tmp_path):
    root = tmp_path / "p"
    _write(search_env / "-p" / "s1.jsonl", [_user("x", cwd=str(root / "a"))])
    assert ca.main(["protect", "--project", str(root), "--note", "proj"]) == 0
    added = _store()["projects"][str(root)]["added"]
    assert ca.main(["unprotect", "--project", str(root), "--purge"]) == 0
    assert ca._archived_paths("s1") == []
    assert ca.main(["protect", "--undo", str(root)]) == 0
    assert _store()["projects"] == {str(root): {"note": "proj", "added": added}}
    assert ca._archived_paths("s1")


def test_undo_nothing(protect_env, capsys):
    assert ca.main(["protect", "--undo"]) == 1
    assert "nothing to undo" in capsys.readouterr().out
    assert not ca.PROTECTED_FILE.exists()


def test_undo_after_purge_rearchives_from_live(protect_env, capsys):
    assert ca.main(["protect", "abc123"]) == 0
    assert ca.main(["unprotect", "abc123", "--purge"]) == 0
    assert ca._archived_paths("abc123") == []
    assert ca.main(["protect", "--undo", "abc123"]) == 0
    arch = ca.PROTECTED_ARCHIVE / "projects" / "-w" / "abc123.jsonl"
    assert arch.read_bytes() == protect_env.read_bytes()


def test_undo_transcript_gone_warns(protect_env, capsys):
    assert ca.main(["protect", "abc123"]) == 0
    assert ca.main(["unprotect", "abc123", "--purge"]) == 0
    protect_env.unlink()
    capsys.readouterr()
    assert ca.main(["protect", "--undo"]) == 0
    assert "abc123" in _store()["sessions"]
    assert "no live or archived transcript" in capsys.readouterr().out


def test_unprotected_cap_and_age_pruning(protect_env):
    old = [{"kind": "session", "id": f"old{i}", "note": None, "added": "x",
            "removed": _iso(31 + i)} for i in range(3)]
    recent = [{"kind": "session", "id": f"s{i:02d}", "note": None, "added": "x",
               "removed": _iso(1 + i / 100)} for i in range(60)]
    _write_store({"sessions": {"abc123": {"note": None, "added": "a"}},
                  "projects": {}, "unprotected": old + recent})
    store = ca.load_protected()
    assert len(store["unprotected"]) == ca.UNPROTECTED_MAX == 50
    assert [e["id"] for e in store["unprotected"]][:2] == ["s00", "s01"]
    assert all(not e["id"].startswith("old") for e in store["unprotected"])
    assert ca.main(["unprotect", "abc123"]) == 0
    ids = [e["id"] for e in _store()["unprotected"]]
    assert len(ids) == 50 and ids[0] == "abc123" and "s49" not in ids


def test_legacy_store_without_unprotected_key(protect_env, capsys):
    _write_store({"sessions": {"abc123": {"note": "legacy", "added": "a"}},
                  "projects": {}})
    assert ca.load_protected()["unprotected"] == []
    assert ca.main(["protect", "--list"]) == 0
    assert "recently unprotected" not in capsys.readouterr().out
    assert ca.main(["unprotect", "abc123"]) == 0
    assert _store()["unprotected"][0]["note"] == "legacy"


def test_unprotected_view_rows_and_order(search_env, tmp_path, capsys):
    root = tmp_path / "p"
    for sid in ("s1", "s2", "s3", "s4"):
        _write(search_env / "-w" / f"{sid}.jsonl", [_user(sid, cwd="/w")])
    _write(search_env / "-p" / "p1.jsonl", [_user("p", cwd=str(root / "a"))])
    _write_store({"sessions": {"s3": {"note": None, "added": "a"}}, "projects": {},
                  "unprotected": [
                      {"kind": "session", "id": "s1", "removed": _iso(3)},
                      {"kind": "session", "id": "s2", "removed": _iso(1)},
                      {"kind": "project", "path": str(root), "removed": _iso(2)},
                      {"kind": "session", "id": "gone", "removed": _iso(0.5)},
                  ]})
    assert ca.main(["search", "--rows", "--view", "unprotected"]) == 0
    lines = capsys.readouterr().out.splitlines()
    assert [ln.split("\t")[0] for ln in lines] == ["s2", "p1", "s1"]
    assert all("↩" in ln for ln in lines)
    assert ca.main(["search", "--json", "--view", "unprotected"]) == 0
    rows = json.loads(capsys.readouterr().out)
    assert [r["unprotected_at"] is not None for r in rows] == [True] * 3
    assert ca.main(["search", "--list", "--view", "unprotected"]) == 0
    assert ca.main(["protect", "--list"]) == 0
    out = capsys.readouterr().out
    assert "recently unprotected" in out and str(root) in out


def test_toggle_on_project_derived_row_restores_project(search_env, tmp_path):
    root = tmp_path / "p"
    _write(search_env / "-p" / "p1.jsonl", [_user("p", cwd=str(root / "a"))])
    assert ca.main(["protect", "--project", str(root)]) == 0
    assert ca.main(["unprotect", "--project", str(root)]) == 0
    assert ca.main(["protect", "--toggle", "p1"]) == 0
    store = _store()
    assert list(store["projects"]) == [str(root)]
    assert store["sessions"] == {} and store["unprotected"] == []


# --- resume -----------------------------------------------------------------

def test_resume_by_prefix(protect_env, monkeypatch, capsys):
    launched = _pick(monkeypatch, "unused")
    assert ca.main(["resume", "abc", "--", "--model", "x"]) == 0
    assert launched == [["--resume", "abc123", "--model", "x"]]
    assert "no longer exists" in capsys.readouterr().out  # /w is not a dir


def test_resume_unknown_or_ambiguous(protect_env, monkeypatch, capsys):
    launched = _pick(monkeypatch, "unused")
    for target in ("ab", "zz"):
        with pytest.raises(SystemExit) as exc:
            ca.main(["resume", target])
        assert exc.value.code == 2
    out = capsys.readouterr().out
    assert "ambiguous" in out and "unknown session" in out
    assert launched == []


def test_resume_bad_args(protect_env):
    assert ca.main(["resume"]) == 2
    assert ca.main(["resume", "abc", "abd"]) == 2
    assert ca.main(["resume", "abc", "--bogus"]) == 2
    assert ca.main(["resume", "abc", "--as"]) == 2


def test_resume_as_and_force(protect_env, monkeypatch, capsys):
    _pick(monkeypatch, "unused")
    _write_config([("a@x.org", "A")])
    launched = []
    monkeypatch.setattr(ca, "launch", lambda email, args: launched.append((email, args)))
    _session_file(ca.CLAUDE_HOME, 42, "abc123", procStart="7")
    _fake_proc(ca.PROC_ROOT, 42, "7")
    assert ca.main(["resume", "abc123", "--as", "A"]) == 1
    assert "already running" in capsys.readouterr().out
    assert ca.main(["resume", "abc123", "--as", "A", "--force-resume"]) == 0
    assert launched == [("a@x.org", ["--resume", "abc123"])]


def test_resume_restores_archived(protect_env, monkeypatch, capsys):
    assert ca.main(["protect", "abc123"]) == 0
    data = protect_env.read_bytes()
    protect_env.unlink()
    launched = _pick(monkeypatch, "unused")
    assert ca.main(["resume", "abc1"]) == 0
    assert launched == [["--resume", "abc123"]]
    assert protect_env.read_bytes() == data
    assert "restored from archive" in capsys.readouterr().out


# --- remind -----------------------------------------------------------------

@pytest.fixture(autouse=True)
def _tg_caps(monkeypatch):
    """Each test starts with nothing learned about tg-notify."""
    monkeypatch.setattr(ca, "_TG_MODE", None)
    monkeypatch.setattr(ca, "_TG_API", None)


@pytest.fixture
def remind_env(search_env, tmp_path, monkeypatch):
    """Reminder store and systemd dir in tmp; no session env; git labels and
    every subprocess (tg-notify, systemctl) stubbed unless a test patches them."""
    monkeypatch.setattr(ca, "REMINDERS_FILE", tmp_path / "share" / "reminders.json")
    monkeypatch.setattr(ca, "TG_STATE_FILE", tmp_path / "share" / "tg-state.json")
    monkeypatch.setattr(ca, "SYSTEMD_USER_DIR", tmp_path / "systemd")
    monkeypatch.setattr(ca, "TG_NOTIFY_FALLBACK", tmp_path / "bin" / "tg-notify")
    monkeypatch.delenv("CLAUDE_CODE_SESSION_ID", raising=False)
    monkeypatch.setattr(ca, "_repo_label", lambda cwd: "repo@main")
    monkeypatch.setattr(ca.subprocess, "run",
                        lambda *a, **k: pytest.fail(f"unexpected subprocess {a}"))
    work = tmp_path / "work"
    work.mkdir()
    monkeypatch.chdir(work)
    return work


def _rems() -> list[dict]:
    return json.loads(ca.REMINDERS_FILE.read_text())["reminders"]


CHAT = -100123


LEGACY_FLAGS = ("--api", "--reply-markup", "--print-id")


class FakeTg:
    """subprocess.run stand-in for tg-notify. Sends get message ids from 100
    up; `--api` calls answer from `updates` (getUpdates, filtered by offset)
    and `chat_id` (getChat), and fail for methods in `fail` (or every send
    when "send" is in it). The `--api probe!` probe is counted in `probes`.
    With `legacy` set it acts as an older tg-notify: LEGACY_FLAGS exit 2 as
    unknown flags and sends print no id. `calls` keeps every command."""

    def __init__(self):
        self.calls: list[list[str]] = []
        self.legacy = False
        self.probes = 0
        self.sends: list[dict] = []
        self.api: list[tuple[str, dict, bool]] = []
        self.updates: list[dict] = []
        self.fail: set[str] = set()
        self.chat_id = CHAT
        self.next_id = 100

    def __call__(self, cmd, **kw):
        assert cmd[0] == "/opt/bin/tg-notify"
        self.calls.append(cmd)
        if self.legacy:
            bad = next((a for a in cmd[1:] if a in LEGACY_FLAGS), None)
            if bad:
                return ca.subprocess.CompletedProcess(
                    cmd, 2, stdout="", stderr=f"tg-notify: unknown flag {bad}\n")
        if cmd[1:] == ["--api", "probe!"]:
            assert kw["input"] == ""
            self.probes += 1
            return ca.subprocess.CompletedProcess(
                cmd, 2, stdout="", stderr="tg-notify: invalid API method probe!\n")
        if cmd[1] == "--api":
            method, body = cmd[2], json.loads(kw["input"])
            self.api.append((method, body, "--with-chat" in cmd))
            if method in self.fail:
                return ca.subprocess.CompletedProcess(
                    cmd, 1, stdout="", stderr='{"error_code": 400, "description": "Bad"}\n')
            result = {"getChat": {"id": self.chat_id},
                      "getUpdates": [u for u in self.updates
                                     if u["update_id"] >= body.get("offset", 0)]
                      }.get(method, True)
            return ca.subprocess.CompletedProcess(
                cmd, 0, stdout=json.dumps({"ok": True, "result": result}), stderr="")
        if "send" in self.fail:
            return ca.subprocess.CompletedProcess(cmd, 1, stdout="", stderr="boom\n")
        if self.legacy:
            self.sends.append({"cmd": cmd, "markup": None, "message": cmd[-1], "id": None})
            return ca.subprocess.CompletedProcess(cmd, 0, stdout="", stderr="")
        i = cmd.index("--reply-markup")
        assert cmd[-2] == "--print-id"
        self.sends.append({"cmd": cmd, "markup": json.loads(cmd[i + 1]),
                           "message": cmd[-1], "id": self.next_id})
        self.next_id += 1
        return ca.subprocess.CompletedProcess(cmd, 0, stdout=f"{self.next_id - 1}\n",
                                              stderr="")

    def methods(self) -> list[str]:
        return [m for m, _, _ in self.api]

    def edits(self) -> dict[int, list[dict]]:
        """{message_id: inline keyboard row} per editMessageReplyMarkup."""
        return {b["message_id"]: b["reply_markup"]["inline_keyboard"][0]
                for m, b, _ in self.api if m == "editMessageReplyMarkup"}

    def answers(self) -> list[str]:
        return [b["text"] for m, b, _ in self.api if m == "answerCallbackQuery"]


NO_DIGEST = {"digest_last": "2999-01-01T00:00:00+00:00"}


@pytest.fixture
def tg(remind_env, monkeypatch):
    """FakeTg as subprocess.run; tg-state has digest_last in the future, so
    no digest goes out unless a test rewrites it."""
    ca.TG_STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    ca.TG_STATE_FILE.write_text(json.dumps(NO_DIGEST))
    fake = FakeTg()
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/opt/bin/{name}")
    monkeypatch.setattr(ca.subprocess, "run", fake)
    return fake


def _press(uid: int, data: str, mid: int, chat: int = CHAT) -> dict:
    return {"update_id": uid, "callback_query": {
        "id": f"q{uid}", "data": data,
        "message": {"message_id": mid, "chat": {"id": chat}}}}


def _tg_state() -> dict:
    return json.loads(ca.TG_STATE_FILE.read_text())


def _ts_iso(ts: float) -> str:
    return ca.datetime.fromtimestamp(ts).astimezone().isoformat(timespec="seconds")


def _rem(rid: str, due: float, **kw) -> dict:
    rec = {"id": rid, "note": f"note {rid}", "due": _ts_iso(due),
           "created": _ts_iso(due - 3600), "session_id": None, "cwd": "/w",
           "repo_label": "repo@main", "status": "pending", "fired_at": None,
           "attempts": 0, "last_error": None}
    rec.update(kw)
    return rec


def _write_rems(rems: list[dict]) -> None:
    ca.REMINDERS_FILE.parent.mkdir(parents=True, exist_ok=True)
    ca.REMINDERS_FILE.write_text(json.dumps({"reminders": rems}))


@pytest.mark.parametrize("text,secs", [
    ("30m", 1800), ("3h", 10800), ("2d", 172800), ("2w", 1209600),
    ("1d12h", 129600), ("1h30m", 5400),
])
def test_parse_duration(text, secs):
    assert ca.parse_duration(text) == secs


@pytest.mark.parametrize("text", ["", "3", "h", "3x", "0m", "1h 2m", "-1h", "1.5h"])
def test_parse_duration_rejects(text):
    with pytest.raises(ValueError):
        ca.parse_duration(text)


def test_parse_when():
    dt = ca.datetime
    now = dt(2026, 11, 5, 14, 0).timestamp()
    assert ca.parse_when("2026-11-05 15:30", now) == dt(2026, 11, 5, 15, 30).timestamp()
    assert ca.parse_when("2026-11-05T15:30", now) == dt(2026, 11, 5, 15, 30).timestamp()
    assert ca.parse_when("15:30", now) == dt(2026, 11, 5, 15, 30).timestamp()
    assert ca.parse_when("13:00", now) == dt(2026, 11, 6, 13, 0).timestamp()
    assert ca.parse_when("14:00", now) == dt(2026, 11, 6, 14, 0).timestamp()
    for bad in ("2026-11-05 13:00", "2026-11-05 14:00", "bogus", "25:00", "2026-13-01 10:00"):
        with pytest.raises(ValueError):
            ca.parse_when(bad, now)


def test_relative():
    assert ca._relative(1000 + 3 * 3600, 1000) == "in 3h"
    assert ca._relative(1000 + 90 * 60, 1000) == "in 1h30m"
    assert ca._relative(1000, 1000 + 26 * 3600 + 120) == "1d2h ago"
    assert ca._relative(1000, 1030) == "30s ago"


def test_remind_add_env_session_protects(protect_env, remind_env, monkeypatch, capsys):
    monkeypatch.setenv("CLAUDE_CODE_SESSION_ID", "abc123")
    before = time.time()
    assert ca.main(["remind", "add", "--in", "3h", "check", "the", "deploy"]) == 0
    (rec,) = _rems()
    assert set(rec) >= {"id", "note", "due", "created", "session_id", "cwd",
                        "repo_label", "status", "fired_at", "attempts", "last_error",
                        "acked_at", "acked_via", "tg_message_id"}
    assert (rec["acked_at"], rec["acked_via"], rec["tg_message_id"]) == (None, None, None)
    assert len(rec["id"]) == 6 and int(rec["id"], 16) >= 0
    assert rec["note"] == "check the deploy"
    assert rec["session_id"] == "abc123"
    assert rec["cwd"] == str(remind_env)
    assert rec["repo_label"] == "repo@main"
    assert (rec["status"], rec["fired_at"], rec["attempts"], rec["last_error"]) == (
        "pending", None, 0, None)
    due = ca._iso_ts(rec["due"])
    assert before + 3 * 3600 - 1 <= due <= time.time() + 3 * 3600
    assert "+" in rec["due"][10:] or "-" in rec["due"][10:]  # has an offset
    assert _store()["sessions"]["abc123"]["note"] == f"reminder {rec['id']}: check the deploy"
    out = capsys.readouterr().out
    assert rec["id"] in out and "in 3h" in out


def test_remind_add_keeps_existing_protect_note(protect_env, remind_env, monkeypatch):
    assert ca.main(["protect", "abc123", "--note", "infra"]) == 0
    monkeypatch.setenv("CLAUDE_CODE_SESSION_ID", "abc123")
    assert ca.main(["remind", "add", "--in", "1h", "x"]) == 0
    assert _store()["sessions"]["abc123"]["note"] == "infra"


def test_remind_add_without_session(remind_env):
    assert ca.main(["remind", "add", "--at", "23:59", "no", "session"]) == 0
    (rec,) = _rems()
    assert rec["session_id"] is None
    assert not ca.PROTECTED_FILE.exists()
    due = ca.datetime.fromisoformat(rec["due"])
    assert (due.hour, due.minute) == (23, 59)


def test_remind_add_no_protect_and_session_prefix(protect_env, remind_env, monkeypatch):
    monkeypatch.setenv("CLAUDE_CODE_SESSION_ID", "abc123")
    assert ca.main(["remind", "add", "--in", "1h", "--session", "abd", "--no-protect",
                    "x"]) == 0
    (rec,) = _rems()
    assert rec["session_id"] == "abd999"
    assert not ca.PROTECTED_FILE.exists()
    with pytest.raises(SystemExit) as exc:
        ca.main(["remind", "add", "--in", "1h", "--session", "zz", "x"])
    assert exc.value.code == 2
    assert len(_rems()) == 1


def test_remind_add_unknown_env_session_still_saves(remind_env, monkeypatch, capsys):
    monkeypatch.setenv("CLAUDE_CODE_SESSION_ID", "fresh-session")
    assert ca.main(["remind", "add", "--in", "1h", "x"]) == 0
    (rec,) = _rems()
    assert rec["session_id"] == "fresh-session"
    assert "could not protect" in capsys.readouterr().out


def test_remind_add_rejects(remind_env):
    past = (ca.datetime.now() - ca.timedelta(days=1)).strftime("%Y-%m-%d %H:%M")
    for args in (["--in", "1h"], ["x"], ["--in", "1h", "--at", "10:00", "x"],
                 ["--in", "soon", "x"], ["--at", past, "x"], ["--in"],
                 ["--in", "1h", "--bogus", "x"], ["--at", "nope", "x"]):
        assert ca.main(["remind", "add", *args]) == 2, args
    assert ca.main(["remind", "add", "--in", "1h", "x", "--", "y"]) == 2
    assert ca.main(["remind"]) == 2
    assert ca.main(["remind", "bogus"]) == 2
    assert not ca.REMINDERS_FILE.exists()


def _list_store(now: float) -> None:
    _write_rems([_rem("aaa111", now + 7230, session_id="abc123def456"),
                 _rem("bbb222", now + 600, note="soonest"),
                 _rem("ccc333", now - 60, status="cancelled", cancelled_at=_ts_iso(now)),
                 _rem("ddd444", now - 60, status="fired", fired_at=_ts_iso(now)),
                 _rem("eee555", now - 7200, status="fired", fired_at=_ts_iso(now)),
                 _rem("fff666", now - 90, status="fired", fired_at=_ts_iso(now),
                      acked_at=_ts_iso(now), acked_via="manual")])


def test_remind_list(remind_env, monkeypatch, capsys):
    monkeypatch.setattr(ca.console, "width", 120)
    now = time.time()
    _list_store(now)
    assert ca.main(["remind", "list"]) == 0
    out = capsys.readouterr().out
    # missed (soonest due first), then pending
    assert (out.index("eee555") < out.index("ddd444") < out.index("bbb222")
            < out.index("aaa111"))
    assert "abc123de" in out and "abc123def" not in out
    assert "ccc333" not in out and "fff666" not in out
    assert "in 2h" in out and "repo@main" in out
    assert "state" in out and out.count("MISSED") == 2 and "pending" in out

    assert ca.main(["remind", "list", "--missed"]) == 0
    out = capsys.readouterr().out
    assert "eee555" in out and "ddd444" in out
    assert not any(i in out for i in ("aaa111", "bbb222", "ccc333", "fff666"))

    assert ca.main(["remind", "list", "--all"]) == 0
    out = capsys.readouterr().out
    assert all(i in out for i in ("aaa111", "bbb222", "ccc333", "ddd444", "eee555",
                                  "fff666"))
    assert "acked" in out and "cancelled" in out

    assert ca.main(["remind", "list", "--json"]) == 0
    out = json.loads(capsys.readouterr().out)
    assert [r["id"] for r in out] == ["eee555", "ddd444", "bbb222", "aaa111"]
    assert [r["state"] for r in out] == ["missed", "missed", "pending", "pending"]
    assert all(r["acked_at"] is None and r["acked_via"] is None
               and r["tg_message_id"] is None for r in out)
    assert ca.main(["remind", "list", "--missed", "--json"]) == 0
    assert [r["id"] for r in json.loads(capsys.readouterr().out)] == ["eee555", "ddd444"]
    assert ca.main(["remind", "list", "--all", "--json"]) == 0
    out = {r["id"]: r for r in json.loads(capsys.readouterr().out)}
    assert len(out) == 6
    assert out["fff666"]["state"] == "acked" and out["fff666"]["acked_via"] == "manual"
    assert out["ccc333"]["state"] == "cancelled"
    assert ca.main(["remind", "list", "--all", "--missed"]) == 2
    assert ca.main(["remind", "list", "--bogus"]) == 2


def test_remind_list_empty(remind_env, capsys):
    assert ca.main(["remind", "list"]) == 0
    assert "no pending or missed reminders" in capsys.readouterr().out
    assert ca.main(["remind", "list", "--missed"]) == 0
    assert "no missed reminders" in capsys.readouterr().out


def test_reminder_state():
    assert ca._reminder_state(_rem("a", 0)) == "pending"
    assert ca._reminder_state(_rem("a", 0, status="cancelled")) == "cancelled"
    assert ca._reminder_state(_rem("a", 0, status="fired")) == "missed"
    assert ca._reminder_state(_rem("a", 0, status="fired",
                                   acked_at="2026-11-05T10:00:00+01:00")) == "acked"


def test_ack_reminder():
    now = 1_800_000_000.0
    rem = _rem("a", now - 60, status="fired", fired_at=_ts_iso(now - 60))
    assert ca.ack_reminder(rem, "telegram", now) is True
    assert (rem["acked_at"], rem["acked_via"]) == (_ts_iso(now), "telegram")
    assert ca.ack_reminder(rem, "manual", now + 60) is False  # already acked
    assert rem["acked_via"] == "telegram"
    for rec in (_rem("p", now), _rem("c", now, status="cancelled")):
        assert ca.ack_reminder(rec, "manual", now) is False
        assert "acked_at" not in rec
    with pytest.raises(ValueError):
        ca.ack_reminder(_rem("b", now, status="fired"), "email", now)


def test_remind_ack(remind_env, capsys):
    now = time.time()
    _list_store(now)
    before = time.time()
    assert ca.main(["remind", "ack", "ddd"]) == 0
    assert "acked" in capsys.readouterr().out
    by_id = {r["id"]: r for r in _rems()}
    assert by_id["ddd444"]["acked_via"] == "manual"
    assert ca._iso_ts(by_id["ddd444"]["acked_at"]) >= int(before)
    assert by_id["eee555"].get("acked_at") is None

    assert ca.main(["remind", "ack", "ddd444"]) == 0  # already acked
    assert "already acked" in capsys.readouterr().out
    for rid, state in (("aaa111", "pending"), ("ccc333", "cancelled")):
        assert ca.main(["remind", "ack", rid]) == 1
        captured = capsys.readouterr()
        assert f"{rid} is {state}, not missed" in captured.err
        assert captured.out == ""
    assert ca.main(["remind", "ack", "zzzzzz"]) == 1
    assert "unknown reminder" in capsys.readouterr().out
    assert ca.main(["remind", "ack"]) == 2
    assert ca.main(["remind", "ack", "--bogus"]) == 2
    assert ca.main(["remind", "ack", "a", "b"]) == 2


def test_remind_ack_all(remind_env, capsys):
    now = time.time()
    _list_store(now)
    acked_at = {r["id"]: r.get("acked_at") for r in _rems()}
    assert ca.main(["remind", "ack", "--all"]) == 0
    assert "2 reminder(s)" in capsys.readouterr().out
    by_id = {r["id"]: r for r in _rems()}
    assert {i for i, r in by_id.items() if ca._reminder_state(r) == "missed"} == set()
    assert by_id["eee555"]["acked_via"] == by_id["ddd444"]["acked_via"] == "manual"
    assert by_id["fff666"]["acked_at"] == acked_at["fff666"]  # untouched
    assert by_id["aaa111"]["status"] == "pending" and "acked_at" not in by_id["aaa111"]
    assert ca.main(["remind", "ack", "--all"]) == 0
    assert "no missed reminders" in capsys.readouterr().out


def test_remind_rm_and_snooze(protect_env, remind_env, monkeypatch):
    monkeypatch.setenv("CLAUDE_CODE_SESSION_ID", "abc123")
    assert ca.main(["remind", "add", "--in", "1h", "x"]) == 0
    rid = _rems()[0]["id"]
    assert ca.main(["remind", "rm", rid[:4]]) == 0
    (rec,) = _rems()
    assert rec["status"] == "cancelled" and rec["cancelled_at"]
    assert "abc123" in _store()["sessions"]  # still protected
    assert ca.main(["remind", "rm", rid]) == 1  # already cancelled
    assert ca.main(["remind", "rm", "zzzzzz"]) == 1

    before = time.time()
    assert ca.main(["remind", "snooze", rid, "2d"]) == 0
    (rec,) = _rems()
    assert rec["status"] == "pending" and rec["cancelled_at"] is None
    assert ca._iso_ts(rec["due"]) >= before + 2 * 86400 - 1
    assert ca.main(["remind", "snooze", rid, "nope"]) == 2
    assert ca.main(["remind", "snooze", rid]) == 2


def test_remind_snooze_clears_ack(tg):
    now = time.time()
    _write_rems([_rem("aaa111", now - 60, status="fired", fired_at=_ts_iso(now),
                      acked_at=_ts_iso(now), acked_via="manual", tg_message_id=42)])
    assert ca.main(["remind", "snooze", "aaa111", "1h"]) == 0
    (rec,) = _rems()
    assert ca._reminder_state(rec) == "pending"
    assert (rec["fired_at"], rec["acked_at"], rec["acked_via"]) == (None, None, None)
    assert rec["tg_message_id"] == 42
    due = ca.datetime.fromtimestamp(ca._iso_ts(rec["due"]))
    clock = due.strftime("%H:%M" if due.date() == ca.datetime.now().date()
                         else "%d %b %H:%M")
    assert tg.api == [("editMessageReplyMarkup", {"message_id": 42, "reply_markup": {
        "inline_keyboard": [[{"text": f"⏰ snoozed → {clock}",
                              "callback_data": "rem:aaa111:noop"}]]}}, True)]


def test_reminder_message():
    now = 1_800_000_000.0
    rec = _rem("aaa111", now - 60, note="ship <it> & go\nnow", session_id="sid-1",
               created=_ts_iso(now - 3 * 3600), repo_label="r<x>@main")
    msg = ca.reminder_message(rec, now)
    assert msg.split("\n") == [
        "⏰ ship <it> & go now",  # title: tg-notify escapes it
        "set 3h ago · r&lt;x&gt;@main",
        "<code>claude-as resume sid-1</code>",
    ]

    rec.update(due=_ts_iso(now - 600), session_id=None, cwd="/a b/<c>")
    lines = ca.reminder_message(rec, now).split("\n")
    due = ca.datetime.fromtimestamp(now - 600).strftime("%H:%M %d %b")
    assert lines[1] == f"<i>late: due {due}</i>"
    assert lines[3] == "<code>cd '/a b/&lt;c&gt;'</code>"


def test_dispatch_sends_marks_and_prunes(tg, capsys):
    now = time.time()
    _write_rems([
        _rem("due001", now - 10, session_id="sid-1"),
        _rem("fut002", now + 600),
        _rem("old003", now - 40 * 86400, status="cancelled",
             cancelled_at=_ts_iso(now - 31 * 86400)),
        _rem("old004", now - 40 * 86400, status="fired",
             fired_at=_ts_iso(now - 40 * 86400), acked_at=_ts_iso(now - 31 * 86400),
             acked_via="manual"),
        _rem("new005", now - 86400, status="fired", fired_at=_ts_iso(now - 86400)),
        _rem("mis006", now - 90 * 86400, status="fired",
             fired_at=_ts_iso(now - 90 * 86400)),
        _rem("ack007", now - 90 * 86400, status="fired",
             fired_at=_ts_iso(now - 90 * 86400), acked_at=_ts_iso(now - 29 * 86400),
             acked_via="manual"),
    ])
    assert ca.main(["remind", "dispatch"]) == 0
    sent = tg.sends
    assert len(sent) == 1
    assert sent[0]["cmd"][:6] == ["/opt/bin/tg-notify", "--html", "--no-context", "--level",
                                  "info", "--reply-markup"]
    assert sent[0]["message"].startswith("⏰ note due001\n")
    assert "claude-as resume sid-1" in sent[0]["message"]
    assert sent[0]["markup"] == {"inline_keyboard": [[
        {"text": "✅ Ack", "callback_data": "rem:due001:ack"},
        {"text": "⏰ +1h", "callback_data": "rem:due001:1h"},
        {"text": "⏰ +1d", "callback_data": "rem:due001:1d"}]]}
    assert tg.methods() == []  # button presses are remind listen's
    by_id = {r["id"]: r for r in _rems()}
    assert by_id["due001"]["tg_message_id"] == 100
    # missed ones stay; acked ones go 30 days after acked_at
    assert set(by_id) == {"due001", "fut002", "new005", "mis006", "ack007"}
    assert by_id["due001"]["status"] == "fired" and by_id["due001"]["fired_at"]
    assert ca._reminder_state(by_id["due001"]) == "missed"
    assert by_id["fut002"]["status"] == "pending"
    capsys.readouterr()

    assert ca.main(["remind", "dispatch"]) == 0
    assert len(sent) == 1
    assert capsys.readouterr() == ("", "")


def test_dispatch_failure_retries(remind_env, monkeypatch, capsys):
    _write_rems([_rem("due001", time.time() - 10)])
    monkeypatch.setattr(ca.shutil, "which", lambda name: None)
    calls = []
    results = iter([ca.subprocess.CompletedProcess([], 1, stdout="", stderr="x\nboom\n"),
                    ca.subprocess.TimeoutExpired("tg-notify", 60),
                    ca.subprocess.CompletedProcess([], 0, stdout="", stderr="")])

    def fake_run(cmd, **kw):
        calls.append(cmd[0])
        res = next(results)
        if isinstance(res, Exception):
            raise res
        return res

    monkeypatch.setattr(ca.subprocess, "run", fake_run)
    assert ca.main(["remind", "dispatch"]) == 1
    (rec,) = _rems()
    assert (rec["status"], rec["attempts"]) == ("pending", 1)
    assert "boom" in rec["last_error"]
    assert ca.main(["remind", "dispatch"]) == 1
    assert _rems()[0]["attempts"] == 2
    assert ca.main(["remind", "dispatch"]) == 0
    assert _rems()[0]["status"] == "fired"
    assert calls == [str(ca.TG_NOTIFY_FALLBACK)] * 3
    assert "boom" in capsys.readouterr().err


def test_dispatch_quiet_without_store(remind_env, capsys):
    assert ca.main(["remind", "dispatch"]) == 0
    assert capsys.readouterr() == ("", "")
    assert not ca.REMINDERS_FILE.exists()


def _missed(rid: str, mid: int | None, now: float, **kw) -> dict:
    return _rem(rid, now - 60, status="fired", fired_at=_ts_iso(now - 60),
                tg_message_id=mid, **kw)


def _hhmm(ts: float) -> str:
    return ca.datetime.fromtimestamp(ts).strftime("%H:%M")


def test_tg_press_ack_offset_and_chat_cached(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", 101, now)])
    tg.updates = [_press(7, "rem:aaa111:ack", 100)]
    before = time.time()
    assert ca.tg_poll() is True
    by_id = {r["id"]: r for r in _rems()}
    assert by_id["aaa111"]["acked_via"] == "telegram"
    assert ca._iso_ts(by_id["aaa111"]["acked_at"]) >= int(before)
    assert ca._reminder_state(by_id["bbb222"]) == "missed"
    assert tg.methods() == ["getChat", "getUpdates", "answerCallbackQuery",
                            "editMessageReplyMarkup"]
    assert tg.api[0] == ("getChat", {}, True)
    assert tg.api[1][1] == {"offset": 0, "timeout": 0,
                            "allowed_updates": ["callback_query"]}
    assert tg.api[2][1] == {"callback_query_id": "q7", "text": "acked"}
    assert tg.edits() == {100: [{"text": f"✅ acked {_hhmm(time.time())} · ↩ undo",
                                 "callback_data": "rem:aaa111:unack"}]}
    assert _tg_state() == {"chat_id": CHAT, "offset": 8, **NO_DIGEST}
    assert "acked aaa111 via telegram" in capsys.readouterr().out

    tg.api.clear()
    tg.chat_id = 999  # cached, not asked again
    assert ca.tg_poll() is True
    assert tg.methods() == ["getUpdates"]
    assert tg.api[0][1]["offset"] == 8
    assert capsys.readouterr() == ("", "")


@pytest.mark.parametrize("action,secs", [("1h", 3600), ("1d", 86400)])
def test_tg_press_snooze(tg, action, secs):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now, acked_at=None, acked_via=None)])
    tg.updates = [_press(1, f"rem:aaa111:{action}", 100)]
    before = time.time()
    assert ca.tg_poll() is True
    (rec,) = _rems()
    assert ca._reminder_state(rec) == "pending"
    due = ca._iso_ts(rec["due"])
    assert before + secs - 1 <= due <= time.time() + secs
    assert rec["tg_message_id"] == 100
    (answer,) = tg.answers()
    assert answer.startswith("snoozed → ") and answer.endswith(_hhmm(due))
    assert rec["snoozed_from"] == {"due": _ts_iso(now - 60), "fired_at": _ts_iso(now - 60)}
    (row,) = tg.edits().values()
    assert row == [{"text": f"⏰ {answer} · ↩ undo", "callback_data": "rem:aaa111:unsnooze"}]


def test_snooze_records_snoozed_from_only_when_missed():
    now = time.time()
    missed = _missed("aaa111", 100, now)
    acked = _missed("bbb222", 101, now, acked_at=_ts_iso(now), acked_via="manual")
    pending = _rem("ccc333", now + 600, snoozed_from={"due": "x", "fired_at": "y"})
    for rec in (missed, acked, pending):
        ca.snooze_reminder(rec, now + 3600)
    assert missed["snoozed_from"] == {"due": _ts_iso(now - 60), "fired_at": _ts_iso(now - 60)}
    assert acked["snoozed_from"] is None and pending["snoozed_from"] is None
    assert ca.tg_markup(acked, now)["inline_keyboard"][0][0]["callback_data"] == "rem:bbb222:noop"


def test_tg_press_unsnooze(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    tg.updates = [_press(1, "rem:aaa111:1h", 100), _press(2, "rem:aaa111:unsnooze", 100)]
    assert ca.tg_poll() is True
    (rec,) = _rems()
    assert ca._reminder_state(rec) == "missed"
    assert (rec["due"], rec["fired_at"]) == (_ts_iso(now - 60), _ts_iso(now - 60))
    assert rec["snoozed_from"] is None and rec["tg_message_id"] == 100
    assert tg.answers()[1] == "snooze undone"
    assert tg.edits() == {100: ca.tg_actions("aaa111")["inline_keyboard"][0]}
    assert ca.tg_markup(rec) == ca.tg_actions("aaa111")
    assert "unsnoozed aaa111 via telegram" in capsys.readouterr().out


def test_unsnooze_noop_without_snoozed_from():
    now = time.time()
    plain = _rem("aaa111", now + 600)
    old = _rem("bbb222", now + 600, snoozed_from=None)
    missed = _missed("ccc333", 100, now, snoozed_from={"due": "x", "fired_at": "y"})
    for rec in (plain, old, missed):
        before = dict(rec)
        assert ca.unsnooze_reminder(rec) is False
        assert rec == before


def test_refire_ack_and_cancel_clear_snoozed_from(remind_env, monkeypatch, capsys):
    now = time.time()
    was = {"due": _ts_iso(now - 7200), "fired_at": _ts_iso(now - 7200)}
    _write_rems([_rem("aaa111", now - 10, snoozed_from=was),
                 _rem("bbb222", now + 600, snoozed_from=was)])
    monkeypatch.setattr(ca.shutil, "which", lambda name: None)
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw: ca.subprocess.CompletedProcess(
        [], 0, stdout="", stderr=""))
    assert ca.main(["remind", "dispatch"]) == 0
    assert ca.main(["remind", "rm", "bbb222"]) == 0
    by_id = {r["id"]: r for r in _rems()}
    assert ca._reminder_state(by_id["aaa111"]) == "missed"
    assert by_id["aaa111"]["snoozed_from"] is None
    assert ca.unsnooze_reminder(by_id["aaa111"]) is False
    assert by_id["bbb222"]["snoozed_from"] is None
    rec = _missed("ccc333", 100, now, snoozed_from=was)
    assert ca.ack_reminder(rec, "manual", now) and rec["snoozed_from"] is None


def test_tg_press_already_acked_and_noop(tg):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now, acked_at=_ts_iso(now), acked_via="manual")])
    tg.updates = [_press(1, "rem:aaa111:ack", 100), _press(2, "rem:aaa111:noop", 100)]
    assert ca.tg_poll() is True
    assert tg.answers() == ["already acked", f"✅ acked {_hhmm(now)}"]
    assert _rems()[0]["acked_via"] == "manual"
    assert tg.edits() == {100: [{"text": f"✅ acked {_hhmm(now)} · ↩ undo",
                                 "callback_data": "rem:aaa111:unack"}]}


def test_tg_markup_acked_offers_undo():
    now = time.time()
    rec = _missed("aaa111", 100, now, acked_at=_ts_iso(now), acked_via="manual")
    assert ca.tg_markup(rec, now) == {"inline_keyboard": [[
        {"text": f"✅ acked {_hhmm(now)} · ↩ undo", "callback_data": "rem:aaa111:unack"}]]}


def test_tg_press_unack(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now, acked_at=_ts_iso(now), acked_via="telegram")])
    tg.updates = [_press(1, "rem:aaa111:unack", 100)]
    assert ca.tg_poll() is True
    (rec,) = _rems()
    assert ca._reminder_state(rec) == "missed"
    assert (rec["acked_at"], rec["acked_via"]) == (None, None)
    assert rec["tg_message_id"] == 100
    assert tg.answers() == ["ack undone"]
    assert tg.edits() == {100: ca.tg_actions("aaa111")["inline_keyboard"][0]}
    assert ca.tg_markup(rec) == ca.tg_actions("aaa111")
    assert "unacked aaa111 via telegram" in capsys.readouterr().out


def test_unack_reminder_only_when_acked():
    now = time.time()
    missed = _missed("aaa111", 100, now)
    pending = _rem("bbb222", now + 600)
    for rec in (missed, pending):
        before = dict(rec)
        assert ca.unack_reminder(rec) is False
        assert rec == before


def test_tg_press_unack_stale(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _rem("bbb222", now + 600, tg_message_id=101)])
    tg.updates = [_press(1, "rem:aaa111:unack", 100), _press(2, "rem:bbb222:unack", 101)]
    assert ca.tg_poll() is True
    by_id = {r["id"]: r for r in _rems()}
    assert ca._reminder_state(by_id["aaa111"]) == "missed"
    assert ca._reminder_state(by_id["bbb222"]) == "pending"
    assert tg.answers() == ["missed", "pending"]
    edits = tg.edits()
    assert edits[100] == ca.tg_actions("aaa111")["inline_keyboard"][0]
    assert edits[101][0]["callback_data"] == "rem:bbb222:noop"
    assert "unacked" not in capsys.readouterr().out


def test_tg_press_mismatch_unknown_and_other_chat(tg):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    tg.updates = [_press(1, "rem:aaa111:ack", 555),      # other message
                  _press(2, "rem:spike:ack", 100),       # unknown id
                  _press(3, "garbage", 100),
                  _press(4, "rem:aaa111:bogus", 100),
                  _press(5, "rem:aaa111:ack", 100, chat=42)]  # other chat: no answer
    tg.fail = {"answerCallbackQuery"}  # too-old queries are ignored quietly
    assert ca.tg_poll() is True
    assert ca._reminder_state(_rems()[0]) == "missed"
    assert tg.answers() == ["unknown reminder"] * 4
    assert "editMessageReplyMarkup" not in tg.methods()
    assert _tg_state()["offset"] == 6


def test_tg_bad_update_still_advances_offset(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    tg.updates = [{"update_id": 3, "callback_query": {"id": "q", "message": "bogus"}},
                  {"update_id": 4, "edited_message": {}},
                  _press(5, "rem:aaa111:ack", 100)]
    assert ca.tg_poll() is True
    assert ca._reminder_state(_rems()[0]) == "acked"
    assert _tg_state()["offset"] == 6
    assert "telegram update 3" in capsys.readouterr().err


def test_tg_no_chat_skips_poll(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    tg.updates = [_press(1, "rem:aaa111:ack", 100)]
    tg.fail = {"getChat"}
    assert ca.tg_poll() is False
    assert tg.methods() == ["getChat"]
    assert _tg_state() == NO_DIGEST
    assert "telegram getChat failed" in capsys.readouterr().err


def test_tg_poll_failure_keeps_offset(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    tg.fail = {"getUpdates"}
    assert ca.tg_poll() is False
    assert ca._reminder_state(_rems()[0]) == "missed"
    assert _tg_state() == {"chat_id": CHAT, **NO_DIGEST}
    assert "telegram getUpdates failed" in capsys.readouterr().err


def test_tg_poll_waits_outside_lock_and_merges_state(tg, monkeypatch):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    _digest_state(None, offset=4)
    tg.updates = [_press(3, "rem:aaa111:1h", 100), _press(4, "rem:aaa111:ack", 100)]
    lock = ca.REMINDERS_FILE.with_name("reminders.json.lock")
    timeouts = []

    def fetch(cmd, **kw):
        if cmd[1:3] == ["--api", "getUpdates"]:
            timeouts.append(kw["timeout"])
            with open(lock, "a") as fh:  # raises BlockingIOError while it is held
                ca.fcntl.flock(fh, ca.fcntl.LOCK_EX | ca.fcntl.LOCK_NB)
                ca.fcntl.flock(fh, ca.fcntl.LOCK_UN)
            # a digest goes out while getUpdates waits
            ca.TG_STATE_FILE.write_text(json.dumps({
                **_tg_state(), "digest_last": "2026-11-09T09:00:00+00:00",
                "digest_message_id": 900, "digest_ids": ["aaa111"]}))
        return tg(cmd, **kw)

    monkeypatch.setattr(ca.subprocess, "run", fetch)
    assert ca.tg_poll(50) is True
    assert tg.api[0][1] == {"offset": 4, "timeout": 50,
                            "allowed_updates": ["callback_query"]}
    assert timeouts == [70]
    assert ca._reminder_state(_rems()[0]) == "acked"  # update 3 was applied before
    assert tg.answers() == ["acked"]
    assert _tg_state() == {"chat_id": CHAT, "offset": 5,
                           "digest_last": "2026-11-09T09:00:00+00:00",
                           "digest_message_id": 900, "digest_ids": ["aaa111"]}


def _listen(monkeypatch, results: list) -> tuple[list, list]:
    """Run remind listen with tg_poll answering from `results` (an exception
    is raised); returns (tg_poll timeouts, sleeps)."""
    polls, sleeps = [], []
    it = iter(results)

    def poll(timeout=0):
        polls.append(timeout)
        res = next(it)
        if isinstance(res, BaseException):
            raise res
        return res

    monkeypatch.setattr(ca, "tg_poll", poll)
    monkeypatch.setattr(ca, "tg_api_supported", lambda: True)
    monkeypatch.setattr(ca.time, "sleep", sleeps.append)
    assert ca.main(["remind", "listen"]) == 0
    return polls, sleeps


def test_remind_listen_backoff(monkeypatch, capsys):
    polls, sleeps = _listen(monkeypatch, [False] * 6 + [True, True, False, False,
                                                       KeyboardInterrupt()])
    assert polls == [50] * 11
    assert sleeps == [5, 10, 20, 40, 60, 60, 5, 10]
    assert "poll failed; retrying in 60s" in capsys.readouterr().err


def test_remind_listen_sigterm(monkeypatch):
    prev = ca.signal.getsignal(ca.signal.SIGTERM)

    def term():
        os.kill(os.getpid(), ca.signal.SIGTERM)
        return True

    monkeypatch.setattr(ca.time, "sleep", lambda s: pytest.fail("no sleep"))
    monkeypatch.setattr(ca, "tg_api_supported", lambda: True)
    calls = []
    monkeypatch.setattr(ca, "tg_poll", lambda timeout=0: calls.append(timeout) or term())
    assert ca.main(["remind", "listen"]) == 0
    assert calls == [50]
    assert ca.signal.getsignal(ca.signal.SIGTERM) == prev
    assert ca.main(["remind", "listen", "x"]) == 2


def test_tg_refire_after_snooze_gets_new_message(tg):
    now = time.time()
    _write_rems([_missed("aaa111", 77, now)])
    tg.updates = [_press(1, "rem:aaa111:1h", 77)]
    assert ca.tg_poll() is True
    rems = _rems()
    rems[0]["due"] = _ts_iso(now - 1)
    _write_rems(rems)
    assert ca.main(["remind", "dispatch"]) == 0
    (rec,) = _rems()
    assert (ca._reminder_state(rec), rec["tg_message_id"]) == ("missed", 100)
    assert len(tg.sends) == 1


def test_cli_ack_rm_edit_messages(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", 101, now),
                 _missed("ccc333", None, now), _rem("ddd444", now + 600, tg_message_id=103)])
    assert ca.main(["remind", "ack", "aaa"]) == 0
    assert list(tg.edits()) == [100]
    assert tg.api[0][2] is True  # --with-chat
    tg.api.clear()
    assert ca.main(["remind", "ack", "--all"]) == 0
    assert list(tg.edits()) == [101]
    tg.api.clear()
    assert ca.main(["remind", "rm", "ddd444"]) == 0
    assert tg.edits() == {103: [{"text": "cancelled", "callback_data": "rem:ddd444:noop"}]}
    capsys.readouterr()

    tg.api.clear()
    tg.fail = {"editMessageReplyMarkup"}
    assert ca.main(["remind", "snooze", "aaa111", "1h"]) == 0
    captured = capsys.readouterr()
    assert "snoozed" in captured.out
    assert "warning: telegram editMessageReplyMarkup failed: exit 1" in captured.err
    assert ca._reminder_state(_rems()[0]) == "pending"


def _local_ts(*args) -> float:
    return ca.datetime(*args).timestamp()


def test_digest_window():
    mon = _local_ts(2026, 11, 9, 9, 0)
    assert ca.datetime.fromtimestamp(mon).weekday() == 0
    prev = _local_ts(2026, 11, 2, 9, 0)
    assert ca.digest_window(mon) == mon
    assert ca.digest_window(mon + 3600) == mon
    assert ca.digest_window(mon - 60) == prev
    assert ca.digest_window(_local_ts(2026, 11, 5, 14, 0)) == prev
    assert ca.digest_window(_local_ts(2026, 11, 15, 23, 59)) == mon


def test_digest_message():
    now = _local_ts(2026, 11, 9, 9, 30)
    msg = ca.digest_message([_missed("aaa111", 1, now, note="ship <it>\n now",
                                     repo_label="r<x>@main")])
    due = ca.datetime.fromtimestamp(now - 60).strftime("%H:%M %d %b")
    assert msg.split("\n") == [
        "⏰ 1 missed reminder(s)",
        f"• ship &lt;it&gt; now · due {due} · r&lt;x&gt;@main · <code>aaa111</code>"]


def _digest_state(last: float | None, **kw) -> None:
    ca.TG_STATE_FILE.write_text(json.dumps(
        {"chat_id": CHAT, "digest_last": _ts_iso(last) if last else None, **kw}))


def test_dispatch_digest_weekly_window(tg, monkeypatch, capsys):
    mon = _local_ts(2026, 11, 9, 9, 0)
    clock = [_local_ts(2026, 11, 5, 14, 0)]
    monkeypatch.setattr(ca.time, "time", lambda: clock[0])
    _write_rems([_missed("new222", 101, mon - 3600), _missed("old111", None, mon - 86400),
                 _rem("pen333", mon + 86400)])
    _digest_state(_local_ts(2026, 11, 2, 9, 30), digest_acked_ids=["gone99"])
    for clock[0] in (_local_ts(2026, 11, 5, 14, 0), mon - 60):
        assert ca.main(["remind", "dispatch"]) == 0
        assert tg.sends == []
    clock[0] = mon + 60
    assert ca.main(["remind", "dispatch"]) == 0
    (sent,) = tg.sends
    assert sent["cmd"][1:5] == ["--html", "--no-context", "--level", "warn"]
    assert sent["markup"] == {"inline_keyboard": [[
        {"text": "✅ Ack all", "callback_data": "dig:ackall"}]]}
    lines = sent["message"].split("\n")
    assert lines[0] == "⏰ 2 missed reminder(s)"
    assert "old111" in lines[1] and "new222" in lines[2]  # oldest due first
    state = _tg_state()
    assert (state["digest_message_id"], state["digest_last"]) == (100, _ts_iso(mon + 60))
    assert state["digest_ids"] == ["old111", "new222"]
    assert state["digest_acked_ids"] == []
    assert "sent digest (2 missed)" in capsys.readouterr().out
    clock[0] = mon + 120
    assert ca.main(["remind", "dispatch"]) == 0
    assert len(tg.sends) == 1


def test_dispatch_digest_none_missed_and_first_run(tg, capsys):
    _write_rems([_rem("pen333", time.time() + 600)])
    ca.TG_STATE_FILE.unlink()  # never checked: the window counts as open
    before = time.time()
    assert ca.main(["remind", "dispatch"]) == 0
    assert tg.sends == []
    assert ca._iso_ts(_tg_state()["digest_last"]) >= int(before)
    assert "digest_message_id" not in _tg_state()
    assert capsys.readouterr() == ("", "")


def test_dispatch_digest_send_failure_retries(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now)])
    _digest_state(ca.digest_window(now) - 60)
    tg.fail = {"send"}
    assert ca.main(["remind", "dispatch"]) == 0
    assert _tg_state()["digest_last"] == _ts_iso(ca.digest_window(now) - 60)
    assert "digest failed: exit 1: boom" in capsys.readouterr().err
    tg.fail = set()
    assert ca.main(["remind", "dispatch"]) == 0
    assert len(tg.sends) == 1 and _tg_state()["digest_message_id"] == 100


def test_digest_ack_all(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", None, now),
                 _missed("ccc333", 102, now, acked_at=_ts_iso(now), acked_via="manual"),
                 _rem("ddd444", now + 600), _missed("eee555", 104, now)])
    ca.TG_STATE_FILE.write_text(json.dumps({
        **NO_DIGEST, "chat_id": CHAT, "digest_message_id": 500,
        "digest_ids": ["aaa111", "bbb222", "ccc333", "ddd444", "gone99"]}))
    tg.updates = [_press(1, "dig:ackall", 499), _press(2, "dig:ackall", 500),
                  _press(3, "dig:noop", 500)]
    assert ca.tg_poll() is True
    by_id = {r["id"]: r for r in _rems()}
    assert by_id["aaa111"]["acked_via"] == by_id["bbb222"]["acked_via"] == "digest"
    assert by_id["ccc333"]["acked_via"] == "manual"
    assert ca._reminder_state(by_id["ddd444"]) == "pending"
    assert ca._reminder_state(by_id["eee555"]) == "missed"  # missed after the digest
    assert tg.answers() == ["old digest", "acked 2", "nothing to do"]
    edits = tg.edits()
    assert set(edits) == {100, 500}
    assert edits[100][0]["text"].startswith("✅ acked ")
    assert edits[500] == [{"text": "✅ acked 2 · ↩ undo", "callback_data": "dig:undo"}]
    assert _tg_state()["digest_acked_ids"] == ["aaa111", "bbb222"]
    assert "acked aaa111, bbb222 via digest" in capsys.readouterr().out


def test_digest_ack_all_none_keeps_noop(tg):
    now = time.time()
    _write_rems([_rem("ddd444", now + 600)])
    ca.TG_STATE_FILE.write_text(json.dumps({
        **NO_DIGEST, "chat_id": CHAT, "digest_message_id": 500, "digest_ids": ["ddd444"]}))
    tg.updates = [_press(1, "dig:ackall", 500)]
    assert ca.tg_poll() is True
    assert tg.edits() == {500: [{"text": "✅ acked 0", "callback_data": "dig:noop"}]}


def test_digest_undo(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", 101, now),
                 _missed("ccc333", 102, now)])
    ca.TG_STATE_FILE.write_text(json.dumps({
        **NO_DIGEST, "chat_id": CHAT, "digest_message_id": 500,
        "digest_ids": ["aaa111", "bbb222", "ccc333"]}))
    tg.updates = [_press(1, "dig:ackall", 500)]
    assert ca.tg_poll() is True
    rems = _rems()
    # bbb222 re-acked via telegram after the digest ack: undo leaves it
    rems[1].update(acked_via="telegram")
    _write_rems(rems)
    tg.api.clear()
    tg.updates = [_press(2, "dig:undo", 499), _press(3, "dig:undo", 500)]
    assert ca.tg_poll() is True
    by_id = {r["id"]: r for r in _rems()}
    assert ca._reminder_state(by_id["aaa111"]) == "missed"
    assert ca._reminder_state(by_id["ccc333"]) == "missed"
    assert by_id["bbb222"]["acked_via"] == "telegram"
    assert tg.answers() == ["old digest", "undid 2"]
    edits = tg.edits()
    assert edits[500] == ca.DIGEST_MARKUP["inline_keyboard"][0]
    assert edits[100] == ca.tg_actions("aaa111")["inline_keyboard"][0]
    assert edits[102] == ca.tg_actions("ccc333")["inline_keyboard"][0]
    assert 101 not in edits
    assert _tg_state()["digest_acked_ids"] == []
    assert "unacked aaa111, ccc333 via digest" in capsys.readouterr().out


def test_remind_digest_cli(tg, capsys):
    now = time.time()
    _write_rems([_rem("pen333", now + 600)])
    assert ca.main(["remind", "digest", "--force"]) == 0
    assert "no missed reminders" in capsys.readouterr().out
    _write_rems([_missed("aaa111", 100, now)])
    assert ca.main(["remind", "digest"]) == 0
    assert "already sent this week" in capsys.readouterr().out
    assert tg.sends == []
    assert ca.main(["remind", "digest", "--force"]) == 0
    assert len(tg.sends) == 1 and _tg_state()["digest_message_id"] == 100
    assert _tg_state()["digest_ids"] == ["aaa111"]
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", 101, now + 1)])
    assert ca.main(["remind", "digest", "--force"]) == 0
    assert len(tg.sends) == 2 and _tg_state()["digest_ids"] == ["aaa111", "bbb222"]
    tg.fail = {"send"}
    assert ca.main(["remind", "digest", "--force"]) == 1
    assert ca.main(["remind", "digest", "--bogus"]) == 2
    assert ca.main(["remind", "digest", "--force", "x"]) == 2


def test_corrupt_store_refuses_write(remind_env, capsys):
    ca.REMINDERS_FILE.parent.mkdir(parents=True)
    ca.REMINDERS_FILE.write_text("{nope")
    with pytest.raises(SystemExit) as exc:
        ca.main(["remind", "add", "--in", "1h", "x"])
    assert exc.value.code == 1
    assert ca.REMINDERS_FILE.read_text() == "{nope"


def test_save_reminders_atomic_under_lock(remind_env, monkeypatch):
    seen = []
    real_flock = ca.fcntl.flock
    monkeypatch.setattr(ca.fcntl, "flock", lambda fd, op: seen.append(op) or real_flock(fd, op))
    real_replace = os.replace
    monkeypatch.setattr(ca.os, "replace", lambda s, d: seen.append(Path(d).name) or real_replace(s, d))
    assert ca.main(["remind", "add", "--in", "1h", "x"]) == 0
    assert seen == [ca.fcntl.LOCK_EX, "reminders.json", ca.fcntl.LOCK_UN]
    assert sorted(p.name for p in ca.REMINDERS_FILE.parent.iterdir()) == [
        "reminders.json", "reminders.json.lock"]


def test_repo_label(tmp_path, monkeypatch):
    if not ca.shutil.which("git"):
        pytest.skip("needs git")
    monkeypatch.setenv("GIT_CEILING_DIRECTORIES", str(tmp_path))
    repo = tmp_path / "myrepo"
    sub = repo / "sub"
    sub.mkdir(parents=True)
    subprocess.run(["git", "init", "-q", "-b", "feat", str(repo)], check=True)
    assert ca._repo_label(str(sub)) == "myrepo@feat"
    plain = tmp_path / "plain"
    plain.mkdir()
    assert ca._repo_label(str(plain)) == str(plain)


def test_remind_units():
    units = ca.remind_units("/home/u/.local/bin/claude-as", "/a:/b")
    service = units["claude-as-remind.service"]
    timer = units["claude-as-remind.timer"]
    assert "Type=oneshot" in service
    assert "Environment=PATH=/a:/b" in service
    assert "ExecStart=/home/u/.local/bin/claude-as remind dispatch" in service
    for line in ("OnCalendar=*:*:00", "Persistent=true", "AccuracySec=10s",
                 "WantedBy=timers.target"):
        assert line in timer.splitlines()
    listen = units["claude-as-remind-listen.service"].splitlines()
    for line in ("Type=simple", "Environment=PATH=/a:/b",
                 "ExecStart=/home/u/.local/bin/claude-as remind listen",
                 "Restart=on-failure", "RestartSec=10", "WantedBy=default.target"):
        assert line in listen


def test_remind_path_env(monkeypatch):
    monkeypatch.setattr(ca.shutil, "which",
                        lambda name: {"sops": "/opt/sops/bin/sops", "uv": "/usr/bin/uv"}.get(name))
    dirs = ca._remind_path().split(":")
    home = str(Path.home())
    assert dirs[0] == f"{home}/.local/bin"
    assert {"/opt/sops/bin", "/usr/local/bin", "/usr/bin"} <= set(dirs)
    assert len(dirs) == len(set(dirs))


def test_remind_install_uninstall(remind_env, monkeypatch, capsys):
    calls = []
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw:
                        calls.append(cmd) or ca.subprocess.CompletedProcess(cmd, 0))
    monkeypatch.setattr(ca, "_remind_exe", lambda: "/x/claude-as")
    monkeypatch.setattr(ca, "_remind_path", lambda: "/p")
    monkeypatch.setattr(ca, "tg_api_supported", lambda: True)
    assert ca.main(["remind", "--install"]) == 0
    units = ca.remind_units("/x/claude-as", "/p")
    for name, text in units.items():
        assert (ca.SYSTEMD_USER_DIR / name).read_text() == text
    assert len(units) == 3
    listener = "claude-as-remind-listen.service"
    assert calls == [["systemctl", "--user", "daemon-reload"],
                     ["systemctl", "--user", "enable", "--now", "claude-as-remind.timer"],
                     ["systemctl", "--user", "enable", "--now", listener],
                     ["systemctl", "--user", "restart", listener]]
    calls.clear()
    assert ca.main(["remind", "--uninstall"]) == 0
    assert calls == [["systemctl", "--user", "disable", "--now", "claude-as-remind.timer"],
                     ["systemctl", "--user", "disable", "--now", listener],
                     ["systemctl", "--user", "daemon-reload"]]
    assert list(ca.SYSTEMD_USER_DIR.iterdir()) == []
    assert ca.main(["remind", "--install", "--uninstall"]) == 2


def test_remind_exe_fallback(monkeypatch):
    monkeypatch.setattr(ca.shutil, "which", lambda name: None)
    assert ca._remind_exe() == os.path.realpath(ca.__file__)
    monkeypatch.setattr(ca.shutil, "which", lambda name: "/h/.local/bin/claude-as")
    assert ca._remind_exe() == "/h/.local/bin/claude-as"


# --- remind: tg-notify missing or older --------------------------------------

def _no_tg_notify(monkeypatch) -> list:
    """tg-notify on neither PATH nor TG_NOTIFY_FALLBACK; returns the list of
    attempted commands."""
    calls = []

    def run(cmd, **kw):
        calls.append(cmd)
        raise FileNotFoundError(2, "No such file or directory", cmd[0])

    monkeypatch.setattr(ca.shutil, "which", lambda name: None)
    monkeypatch.setattr(ca.subprocess, "run", run)
    return calls


def test_dispatch_without_tg_notify_marks_missed(remind_env, monkeypatch, capsys):
    now = time.time()
    _write_rems([_rem("due001", now - 10), _rem("due002", now - 5),
                 _rem("fut003", now + 600), _missed("old004", 50, now)])
    _digest_state(ca.digest_window(now) - 60)
    before = _tg_state()
    calls = _no_tg_notify(monkeypatch)
    assert ca.main(["remind", "dispatch"]) == 0
    assert len(calls) == 1  # the missing binary is remembered
    by_id = {r["id"]: r for r in _rems()}
    for rid in ("due001", "due002"):
        rec = by_id[rid]
        assert ca._reminder_state(rec) == "missed" and rec["fired_at"]
        assert (rec["last_error"], rec["tg_message_id"], rec["attempts"]) == (
            "tg-notify not found", None, 0)
    assert by_id["fut003"]["status"] == "pending"
    out, err = capsys.readouterr()
    assert err.splitlines() == ["not sent due001: tg-notify not found; marked missed",
                                "not sent due002: tg-notify not found; marked missed"]
    assert out == ""
    assert _tg_state() == before  # digest skipped, digest_last kept

    assert ca.main(["remind", "list", "--missed"]) == 0
    listed = capsys.readouterr().out
    assert "due001" in listed and "due002" in listed and "MISSED" in listed
    assert ca.main(["remind", "ack", "old004"]) == 0  # has a tg_message_id
    assert ca.main(["remind", "snooze", "due001", "1h"]) == 0
    assert capsys.readouterr().err == ""
    assert len(calls) == 1


def test_digest_cli_without_tg_notify(remind_env, monkeypatch, capsys):
    _write_rems([_missed("aaa111", None, time.time())])
    _no_tg_notify(monkeypatch)
    assert ca.main(["remind", "digest", "--force"]) == 1
    assert "tg-notify not found; no digest sent" in capsys.readouterr().err
    assert not ca.TG_STATE_FILE.exists()


def test_dispatch_legacy_tg_notify_sends_plain(tg, capsys):
    now = time.time()
    _write_rems([_rem("due001", now - 10), _rem("due002", now - 5)])
    tg.legacy = True
    assert ca.main(["remind", "dispatch"]) == 0
    first, retry, second = tg.calls  # the rejected flags are not tried again
    assert "--reply-markup" in first and "--print-id" in first
    for cmd in (retry, second):
        assert cmd[:5] == ["/opt/bin/tg-notify", "--html", "--no-context", "--level", "info"]
        assert not set(cmd) & set(LEGACY_FLAGS)
    assert [s["message"].split("\n")[0] for s in tg.sends] == ["⏰ note due001",
                                                               "⏰ note due002"]
    for rec in _rems():
        assert ca._reminder_state(rec) == "missed"
        assert (rec["tg_message_id"], rec["last_error"]) == (None, None)
    out, err = capsys.readouterr()
    assert out.splitlines() == ["sent due001", "sent due002"] and err == ""


def test_dispatch_digest_legacy_tg_notify(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", None, now)])
    _digest_state(ca.digest_window(now) - 60)
    tg.legacy = True
    assert ca.main(["remind", "dispatch"]) == 0
    (sent,) = tg.sends
    assert sent["markup"] is None and "--level" in sent["cmd"]
    assert sent["message"].startswith("⏰ 1 missed reminder(s)")
    state = _tg_state()
    assert state["digest_message_id"] is None and state["digest_ids"] == ["aaa111"]
    assert ca._iso_ts(state["digest_last"]) >= int(now)
    assert "sent digest (1 missed)" in capsys.readouterr().out


@pytest.mark.parametrize("legacy,expected", [(False, True), (True, False)])
def test_tg_api_supported(tg, legacy, expected):
    tg.legacy = legacy
    assert ca.tg_api_supported() is expected
    assert ca.tg_api_supported() is expected
    assert tg.calls == [["/opt/bin/tg-notify", "--api", "probe!"]]


def test_tg_api_supported_missing(remind_env, monkeypatch, capsys):
    calls = _no_tg_notify(monkeypatch)
    assert ca.tg_api_supported() is False
    assert ca.tg_api("getChat", {}, with_chat=True) is None
    assert ca.send_notification("x").missing
    assert len(calls) == 1
    assert capsys.readouterr() == ("", "")


def test_tg_api_legacy_quiet_and_edits_skipped(tg, capsys):
    now = time.time()
    _write_rems([_missed("aaa111", 100, now), _missed("bbb222", 101, now)])
    tg.legacy = True
    assert ca.tg_api("getChat", {}, with_chat=True) is None
    assert len(tg.calls) == 1
    assert ca.main(["remind", "ack", "aaa111"]) == 0
    assert ca.main(["remind", "snooze", "bbb222", "1h"]) == 0
    assert len(tg.calls) == 1  # no edits, no probe: --api is known to be missing
    assert capsys.readouterr().err == ""


def test_cli_edits_skipped_when_unsupported(tg, capsys):
    _write_rems([_missed("aaa111", 100, time.time())])
    tg.legacy = True
    assert ca.main(["remind", "ack", "aaa111"]) == 0
    assert tg.calls == [["/opt/bin/tg-notify", "--api", "probe!"]]
    assert tg.edits() == {} and capsys.readouterr().err == ""


def test_remind_listen_unsupported(monkeypatch, capsys):
    monkeypatch.setattr(ca, "tg_api_supported", lambda: False)
    monkeypatch.setattr(ca, "tg_poll", lambda timeout=0: pytest.fail("no poll"))
    prev = ca.signal.getsignal(ca.signal.SIGTERM)
    assert ca.main(["remind", "listen"]) == 0
    assert capsys.readouterr().err == (
        "tg-notify missing or without --api; button presses disabled\n")
    assert ca.signal.getsignal(ca.signal.SIGTERM) == prev


def test_remind_install_without_api(remind_env, monkeypatch, capsys):
    calls = []
    monkeypatch.setattr(ca.subprocess, "run", lambda cmd, **kw:
                        calls.append(cmd) or ca.subprocess.CompletedProcess(cmd, 0))
    monkeypatch.setattr(ca, "_remind_exe", lambda: "/x/claude-as")
    monkeypatch.setattr(ca, "_remind_path", lambda: "/p")
    monkeypatch.setattr(ca, "tg_api_supported", lambda: False)
    listener = "claude-as-remind-listen.service"
    ca.SYSTEMD_USER_DIR.mkdir(parents=True)
    (ca.SYSTEMD_USER_DIR / listener).write_text("old")
    assert ca.main(["remind", "--install"]) == 0
    assert sorted(p.name for p in ca.SYSTEMD_USER_DIR.iterdir()) == [
        "claude-as-remind.service", "claude-as-remind.timer"]
    assert calls == [["systemctl", "--user", "disable", "--now", listener],
                     ["systemctl", "--user", "daemon-reload"],
                     ["systemctl", "--user", "enable", "--now", "claude-as-remind.timer"]]
    out = capsys.readouterr().out
    assert "without --api" in out and "removed" in out
    calls.clear()
    assert ca.main(["remind", "--install"]) == 0  # no listener file left to stop
    assert calls == [["systemctl", "--user", "daemon-reload"],
                     ["systemctl", "--user", "enable", "--now", "claude-as-remind.timer"]]

# --- search: reminders view -------------------------------------------------

def _rem_store(now: float) -> None:
    _write_rems([
        _rem("late01", now + 3 * 3600 + 30, session_id="abc123", note="check deploy"),
        _rem("soon01", now + 1800, note="no session", cwd="/w/x"),
        _rem("fired1", now - 60, status="fired", fired_at=_ts_iso(now - 60)),
        _rem("acked1", now - 120, status="fired", fired_at=_ts_iso(now - 120),
             acked_at=_ts_iso(now - 60), acked_via="manual"),
        _rem("gone01", now + 7200, session_id="zzz999", note="lost session"),
    ])


def test_reminders_view_rows_list_json(protect_env, remind_env, capsys):
    now = time.time()
    _rem_store(now)
    assert ca.main(["search", "--rows", "--view", "reminders"]) == 0
    lines = capsys.readouterr().out.splitlines()
    assert [ln.split("\t")[0] for ln in lines] == ["rem:fired1", "rem:soon01",
                                                   "rem:gone01", "rem:late01"]
    cells = [ca.re.sub(r"\x1b\[[0-9;]*m", "", c).strip()
             for c in lines[3].split("\t")]
    stamp = ca.datetime.fromtimestamp(now + 3 * 3600 + 30).strftime("%m-%d %H:%M")
    assert cells[1].startswith(stamp) and cells[1].endswith("in 3h")
    assert cells[2:6] == ["late01", "check deploy", "abc123", "repo@main"]
    assert lines[1].split("\t")[4].strip() == "-"
    missed = lines[0].split("\t")[1]
    stamp = ca.datetime.fromtimestamp(now - 60).strftime("%m-%d %H:%M")
    assert missed.startswith("\x1b[31m") and f"{stamp} MISSED" in missed

    assert ca.main(["search", "--json", "--view", "reminders"]) == 0
    out = json.loads(capsys.readouterr().out)
    assert [r["id"] for r in out] == ["fired1", "soon01", "gone01", "late01"]
    assert [r["state"] for r in out] == ["missed", "pending", "pending", "pending"]
    assert out[3]["session_id"] == "abc123" and out[3]["note"] == "check deploy"
    assert ca.main(["search", "--json", "--view", "reminders", "DEPLOY"]) == 0
    assert [r["id"] for r in json.loads(capsys.readouterr().out)] == ["late01"]

    assert ca.main(["search", "--list", "--view", "reminders"]) == 0
    out = capsys.readouterr().out
    assert "late01" in out and "check deploy" in out and "abc123" in out
    assert "fired1" in out and "MISSED" in out and "acked1" not in out
    assert ca.main(["search", "--list", "--view", "reminders", "--grep", "x"]) == 2


def test_reminders_view_empty(remind_env, monkeypatch, capsys):
    assert ca.main(["search", "--rows", "--view", "reminders"]) == 0
    assert capsys.readouterr().out == ""
    monkeypatch.setattr(ca.shutil, "which", lambda name: f"/usr/bin/{name}")
    monkeypatch.setattr(ca, "_sync_quietly", lambda rows=None: None)
    assert ca.main(["search", "--view", "reminders"]) == 0
    assert "no pending or missed reminders" in capsys.readouterr().out


def test_reminder_pick_resumes_session(protect_env, remind_env, monkeypatch):
    _rem_store(time.time())
    seen = {}
    launched = _pick(monkeypatch, "rem:late01")
    real = ca.subprocess.run

    def spy(cmd, **kw):
        seen["cmd"], seen["input"] = cmd, kw["input"]
        return real(cmd, **kw)

    monkeypatch.setattr(ca.subprocess, "run", spy)
    assert ca.main(["search", "--view", "reminders"]) == 0
    assert launched == [["--resume", "abc123"]]
    assert "--prompt=reminders (from all)> " in seen["cmd"]
    assert f"--header={ca.REMIND_HEADER}" in seen["cmd"]
    assert "start:unbind(ctrl-p,ctrl-n)" in seen["cmd"]
    assert seen["input"].split("\t")[0] == "rem:fired1"


def test_reminder_pick_does_not_ack(protect_env, remind_env, monkeypatch):
    now = time.time()
    _write_rems([_rem("mis001", now - 60, status="fired", fired_at=_ts_iso(now - 60),
                      session_id="abc123")])
    launched = _pick(monkeypatch, "rem:mis001")
    assert ca.main(["search", "--view", "reminders"]) == 0
    assert launched == [["--resume", "abc123"]]
    assert ca._reminder_state(_rems()[0]) == "missed"


def test_reminder_pick_running_session_refused(protect_env, remind_env, monkeypatch,
                                               capsys):
    _rem_store(time.time())
    _session_file(ca.CLAUDE_HOME, 42, "abc123", procStart="7", status="working")
    _fake_proc(ca.PROC_ROOT, 42, "7")
    launched = _pick(monkeypatch, "rem:late01")
    assert ca.main(["search", "--view", "reminders"]) == 1
    assert launched == []
    assert "already running" in capsys.readouterr().out


@pytest.mark.parametrize("rid,why", [("soon01", "no session"),
                                     ("gone01", "zzz999 not in the session index")])
def test_reminder_pick_without_session(protect_env, remind_env, monkeypatch, capsys,
                                       rid, why):
    _rem_store(time.time())
    launched = _pick(monkeypatch, f"rem:{rid}")
    assert ca.main(["search", "--view", "reminders"]) == 1
    assert launched == []
    out = capsys.readouterr().out
    assert why in out
    cwd = "/w/x" if rid == "soon01" else "/w"
    assert f"cd {cwd}" in out


def test_reminder_pick_unknown_reminder(protect_env, remind_env, monkeypatch, capsys):
    _rem_store(time.time())
    launched = _pick(monkeypatch, "rem:nope00")
    assert ca.main(["search", "--view", "reminders"]) == 1
    assert launched == []
    assert "unknown reminder" in capsys.readouterr().out


def test_reminder_preview(protect_env, remind_env, capsys):
    now = time.time()
    _rem_store(now)
    assert ca.main(["search", "--preview", "rem:late01"]) == 0
    out = capsys.readouterr().out
    assert "note:    check deploy" in out
    assert "status:  pending" in out and "cwd:     /w" in out
    assert "session: abc123" in out and "created: " in out
    assert "(in 3h)" in out
    assert "id:      abc123" in out and "[you] keep me" in out  # session preview
    assert out.index("session: abc123") < out.index("id:      abc123")

    assert ca.main(["search", "--preview", "rem:soon01"]) == 0
    out = capsys.readouterr().out
    assert "session: -" in out and "id: " not in out
    assert "acked:" not in out and "fired:" not in out
    assert ca.main(["search", "--preview", "rem:nope00"]) == 1

    assert ca.main(["search", "--preview", "rem:fired1"]) == 0
    out = capsys.readouterr().out
    assert "status:  missed" in out and "fired:   " in out and "acked:" not in out
    assert ca.main(["search", "--preview", "rem:acked1"]) == 0
    out = capsys.readouterr().out
    assert "status:  acked" in out
    assert "acked:   " in out and "(1m ago) via manual" in out


def _transform(bind: str, key: str, prompt: str) -> str:
    snippet = bind.removeprefix(f"{key}:transform:")
    return subprocess.run(["sh", "-c", snippet], capture_output=True, text=True,
                          env={**os.environ, "FZF_PROMPT": prompt}).stdout


def test_fzf_ctrl_r_toggles_reminders(search_env):
    cmd = ca._fzf_command("", "pat")
    bind = next(a for a in cmd if a.startswith("ctrl-r:"))
    script = str(Path(ca.__file__).resolve())

    out = _transform(bind, "ctrl-r", "protected> ")
    assert out.startswith("change-prompt[reminders (from protected)> ]")
    assert f"change-header[{ca.REMIND_HEADER}]" in out
    assert "+unbind(ctrl-p,ctrl-n)+rebind(ctrl-a,ctrl-x,ctrl-z)+" in out
    assert out.endswith("search --rows --view reminders") and script in out
    assert "GREP" not in out

    out = _transform(bind, "ctrl-r", "reminders (from protected)> ")
    assert out.startswith("change-prompt(protected> )")
    assert f"change-header[{ca.FZF_HEADER}]" in out
    assert "+rebind(ctrl-p,ctrl-n)+unbind(ctrl-a,ctrl-x,ctrl-z)+" in out
    assert out.endswith(f'search --rows --view protected --grep "${ca.GREP_ENV}"')


def test_fzf_ctrl_s_from_reminders_restores_session_keys(search_env):
    cmd = ca._fzf_command("", None)
    bind = next(a for a in cmd if a.startswith("ctrl-s:"))
    out = _transform(bind, "ctrl-s", "reminders (from active)> ")
    assert out.startswith("change-prompt(all> )")
    assert "+rebind(ctrl-p,ctrl-n)+unbind(ctrl-a,ctrl-x,ctrl-z)+" in out
    assert out.endswith("search --rows --view all")


@pytest.mark.parametrize("key,expected", [("ctrl-a", "remind ack r1"),
                                          ("ctrl-x", "remind rm r1"),
                                          ("ctrl-z", "remind snooze r1 1h")])
def test_fzf_reminder_action_keys(search_env, key, expected):
    cmd = ca._fzf_command("", "pat")
    bind = next(a for a in cmd if a.startswith(f"{key}:"))
    script = str(Path(ca.__file__).resolve())
    prefix = f"{key}:track-current+execute-silent("
    assert bind.startswith(prefix) and script in bind
    action, reload = bind.removeprefix(prefix).split(")+reload:")
    assert reload.endswith("search --rows --view reminders")
    # fzf substitutes {1} with the quoted hidden id field.
    sh = action.replace("{1}", "'rem:r1'").replace(ca._self_cmd(), "echo")
    out = subprocess.run(["sh", "-c", sh], capture_output=True, text=True).stdout
    assert out.strip() == expected
    assert "start:unbind(ctrl-a,ctrl-x,ctrl-z)" in cmd


# --- data dir resolution -----------------------------------------------------

@pytest.fixture
def no_home(tmp_path, monkeypatch):
    """No $CLAUDE_AS_HOME and an empty $HOME; returns the fake $HOME."""
    monkeypatch.delenv("CLAUDE_AS_HOME", raising=False)
    fake_home = tmp_path / "user-home"
    fake_home.mkdir()
    monkeypatch.setenv("HOME", str(fake_home))
    return fake_home


def test_home_from_env(tmp_path, monkeypatch):
    data = tmp_path / "data"
    data.mkdir()
    monkeypatch.setenv("CLAUDE_AS_HOME", str(data))
    assert ca.as_home() == data.resolve()
    assert ca.accounts_root() == data.resolve() / "accounts"


def test_home_env_wins_over_link(no_home, tmp_path, monkeypatch):
    link = no_home / ".config" / "claude-as" / "home"
    link.parent.mkdir(parents=True)
    os.symlink(tmp_path, link)
    data = tmp_path / "data"
    data.mkdir()
    monkeypatch.setenv("CLAUDE_AS_HOME", str(data))
    assert ca.as_home() == data.resolve()


def test_home_from_config_symlink(no_home, tmp_path):
    data = tmp_path / "data"
    data.mkdir()
    link = no_home / ".config" / "claude-as" / "home"
    link.parent.mkdir(parents=True)
    os.symlink(data, link)
    assert ca.as_home() == data.resolve()


def test_home_missing_exits(no_home):
    assert ca.find_home() is None
    with pytest.raises(SystemExit) as exc:
        ca.as_home()
    assert "CLAUDE_AS_HOME" in str(exc.value.code)
    assert str(no_home / ".config" / "claude-as" / "home") in str(exc.value.code)


def test_home_dangling_link_exits(no_home, tmp_path):
    link = no_home / ".config" / "claude-as" / "home"
    link.parent.mkdir(parents=True)
    os.symlink(tmp_path / "gone", link)
    with pytest.raises(SystemExit):
        ca.as_home()


def test_help_and_file_history_need_no_home(no_home, capsys):
    assert ca.main(["--help"]) == 0
    assert "CLAUDE_AS_HOME" in capsys.readouterr().out
    assert ca._file_history_dirs() == []


def test_load_config_missing_file_exits(tmp_path):
    with pytest.raises(SystemExit) as exc:
        ca.load_config()
    assert str(tmp_path / "config.yaml") in str(exc.value.code)


def test_load_users_reads_config(tmp_path):
    (tmp_path / "config.yaml").write_text(
        "users:\n  Work: w@x.org\n  Home: ''\n  default: d@x.org\n")
    assert ca.parse_users(ca.load_config()) == [("w@x.org", "Work"), ("d@x.org", "default")]
    (tmp_path / "config.yaml").write_text(
        "users:\n  - a@x.org\n  - {email: b@x.org, label: B}\n  - {label: none}\n")
    assert ca.load_users() == [("a@x.org", None), ("b@x.org", "B")]


def test_auth_gate_prints_login_command(tmp_path, capsys):
    cfg = tmp_path / "accounts" / "a@x.org"
    cfg.mkdir(parents=True)
    with pytest.raises(SystemExit):
        ca.auth_gate(cfg, "a@x.org")
    out = capsys.readouterr().out
    assert f"CLAUDE_CONFIG_DIR={cfg} claude auth login --claudeai --email a@x.org\n" in out


def test_top_level_install_is_unknown(capsys):
    assert ca.main(["--install"]) == 2
