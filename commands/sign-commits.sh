#!/usr/bin/env bash
# Sign unsigned commits on the current branch (ahead of upstream/main) using SSH signing.
#
# Usage: sign-commits.sh [<base-ref>]
#   <base-ref> optional. Defaults to @{upstream}, falls back to origin/main, then main.

set -euo pipefail

# --- colors & emoji -----------------------------------------------------------
if [[ -t 1 ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    CYAN=$'\033[36m'
    RESET=$'\033[0m'
else
    BOLD='' DIM='' RED='' GREEN='' YELLOW='' BLUE='' CYAN='' RESET=''
fi

info()    { printf '%sℹ️  %s%s\n'  "$BLUE"   "$*" "$RESET"; }
ok()      { printf '%s✅ %s%s\n'  "$GREEN"  "$*" "$RESET"; }
warn()    { printf '%s⚠️  %s%s\n'  "$YELLOW" "$*" "$RESET"; }
err()     { printf '%s❌ %s%s\n'  "$RED"    "$*" "$RESET" >&2; }
step()    { printf '\n%s%s🔹 %s%s\n' "$BOLD" "$CYAN" "$*" "$RESET"; }

abort() { err "$*"; exit 1; }

# --- must be inside a git repo ------------------------------------------------
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || abort "Not inside a git repository."

# --- resolve base ref ---------------------------------------------------------
step "Resolving base ref"

BASE_REF="${1:-}"
if [[ -z "$BASE_REF" ]]; then
    if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
        BASE_REF='@{upstream}'
    elif git rev-parse --verify origin/main >/dev/null 2>&1; then
        BASE_REF='origin/main'
    elif git rev-parse --verify main >/dev/null 2>&1; then
        BASE_REF='main'
    else
        abort "Could not determine a base ref. Pass one explicitly: sign-commits.sh <base>"
    fi
fi

BASE_SHA="$(git rev-parse --verify "$BASE_REF" 2>/dev/null)" \
    || abort "Base ref '$BASE_REF' does not resolve to a commit."

HEAD_SHA="$(git rev-parse --verify HEAD)"
if [[ "$BASE_SHA" == "$HEAD_SHA" ]]; then
    ok "Nothing to do here, all signed (HEAD == $BASE_REF)"
    exit 0
fi

info "Base:  ${BOLD}${BASE_REF}${RESET} ${DIM}($(git rev-parse --short "$BASE_SHA"))${RESET}"
info "Head:  ${BOLD}HEAD${RESET}     ${DIM}($(git rev-parse --short HEAD))${RESET}"

# --- find unsigned commits ----------------------------------------------------
step "Scanning for unsigned commits"

RANGE="${BASE_SHA}..HEAD"

# %G? signature codes: G good, B bad, U good unknown, X expired, Y expired key,
# R revoked key, E can't check, N no signature.
mapfile -t UNSIGNED < <(git log --reverse --pretty='format:%H %G?%n' "$RANGE" \
    | awk 'NF==2 && $2=="N" {print $1}')

if [[ ${#UNSIGNED[@]} -eq 0 ]]; then
    ok "Nothing to do here, all signed 🎉"
    exit 0
fi

info "Found ${BOLD}${#UNSIGNED[@]}${RESET} unsigned commit(s) in ${BOLD}${RANGE}${RESET}"

# --- verify signing setup -----------------------------------------------------
step "Verifying SSH signing setup"

FORMAT="$(git config --get gpg.format || true)"
if [[ "$FORMAT" != "ssh" ]]; then
    abort "git config gpg.format is '${FORMAT:-unset}', expected 'ssh'. Run: git config --global gpg.format ssh"
fi
ok "gpg.format = ssh"

SIGNING_KEY="$(git config --get user.signingkey || true)"
if [[ -z "$SIGNING_KEY" ]]; then
    abort "git config user.signingkey is not set. Set it to your SSH public key (path or literal)."
fi
ok "user.signingkey is configured"

if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    warn "SSH_AUTH_SOCK is not set — ssh-agent may not be available."
fi

if ! ssh-add -l >/dev/null 2>&1; then
    rc=$?
    if [[ $rc -eq 1 ]]; then
        abort "ssh-agent is running but has no identities. Run: ssh-add <your-key>"
    else
        abort "Cannot reach ssh-agent (ssh-add exit $rc). Start it and add your key."
    fi
fi
ok "ssh-agent reachable with $(ssh-add -l | wc -l) identity(ies) loaded"

# Smoke-test that we can actually produce a signature with the configured key.
SIGN_KEY_PATH="$SIGNING_KEY"
if [[ "$SIGN_KEY_PATH" != /* && "$SIGN_KEY_PATH" != ~* && ! "$SIGN_KEY_PATH" =~ ^ssh- ]]; then
    : # leave as-is
fi
if [[ -f "${SIGN_KEY_PATH/#\~/$HOME}" ]]; then
    if ! printf 'test' | ssh-keygen -Y sign -n git -f "${SIGN_KEY_PATH/#\~/$HOME}" >/dev/null 2>&1; then
        abort "ssh-keygen could not sign with key '$SIGNING_KEY'. Is the matching private key loaded in ssh-agent?"
    fi
    ok "ssh-keygen produced a test signature successfully"
else
    warn "user.signingkey is not a file path — skipping signature smoke test"
fi

# --- show commits & confirm ---------------------------------------------------
step "Commits that will be re-signed"

git --no-pager log --reverse \
    --pretty="format:  ${YELLOW}%h${RESET} ${DIM}%G?${RESET} %s ${DIM}(%an, %ar)${RESET}" \
    "$RANGE"
printf '\n'

printf '\n%s🔏 Re-sign these %d commit(s)? %s[y/N] %s' \
    "$BOLD" "${#UNSIGNED[@]}" "$DIM" "$RESET"
read -r REPLY
case "$REPLY" in
    y|Y|yes|YES) ;;
    *)
        err "Aborted"
        exit 1
        ;;
esac

# --- rebase to sign -----------------------------------------------------------
step "Rebasing with --exec to sign each commit"

if ! git rebase "$BASE_SHA" --exec 'git commit --amend --no-edit -S'; then
    err "Rebase failed. Resolve and run: git rebase --continue   (or: git rebase --abort)"
    exit 1
fi

# --- verify -------------------------------------------------------------------
step "Verifying"

REMAINING="$(git log --pretty='format:%G?' "${BASE_SHA}..HEAD" | grep -c '^N' || true)"
if [[ "$REMAINING" -gt 0 ]]; then
    warn "$REMAINING commit(s) still unsigned — check git config and try again."
    exit 1
fi

ok "All commits in ${BOLD}${RANGE}${RESET}${GREEN} are signed 🎉🔏${RESET}"
