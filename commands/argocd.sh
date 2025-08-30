#!/bin/bash

set -e

DOT_ARGOCD_CONTEXT=${DOT_ARGOCD_CONTEXT?Please define it in your ~/.zsh-additional-rc}
DOT_ARGOCD_NAMESPACE=${DOT_ARGOCD_NAMESPACE:-argocd}


function _run() {
    # Default values
    WATCH=false

    # Argument parsing
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --watch)
                WATCH=true
                ;;
            --)
                shift
                break
                ;;
            *)
                >&2 echo "Unknown option passed to inner function _run: $1"
                exit 1
                ;;
        esac
        shift
    done

    _command="kubie exec --context-headers never "$DOT_ARGOCD_CONTEXT" "$DOT_ARGOCD_NAMESPACE" -- $@"
    if $WATCH; then
        viddy "$_command"
    else
        eval "$_command"
    fi
}

function _get_app() {
    if [ -n "$ARGOCD_PROJECT_NAME" ]; then
        echo "$ARGOCD_PROJECT_NAME"
        return
    fi

    app=$(_run -- argocd app list --core | tail -n +2 | awk '{print $1}' | grep '\-apps' | fzf)

    if ! [ -n "$app" ]; then
        >&2 echo "No app selected."
        exit 1
    fi

    echo "$app"
}

function _argocd_get() {
    app=$(_get_app)
    _run -- argocd app get "$app" --core
}

function _argocd_refresh() {
    app=$(_get_app)
    _run -- argocd app get "$app" --core --refresh
}

function _argocd_watch() {
    app=$(_get_app)
    # Do a refresh first
    _run -- argocd app get "$app" --core --refresh
    # Then just watch
    _run --watch -- argocd app get "$app" --core
}

function _apps() {
    _run -- argocd app list --core | tail -n +2 | cut -d " " -f 1 | awk NF
}

function _usages() {
  echo "Usage: $0 {refresh|watch}"
  exit 1
}

if [ $# -lt 1 ]; then
    _usages
fi

SUBCOMMAND=$1
shift  # Remove sub-command from the arguments list
ARGOCD_PROJECT_NAME="$1"

# Handle the sub-command
case "$SUBCOMMAND" in
  get)
    _argocd_refresh
    ;;
  refresh)
    _argocd_refresh
    ;;
  watch)
    _argocd_watch
    ;;
  apps)
    _apps
    ;;
  *)
    echo "Unknown sub-command: $subcommand"
    _usages $0
    ;;
esac
