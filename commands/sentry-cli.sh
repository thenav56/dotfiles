#!/bin/bash

set -e

CONFIG_FILE="$HOME/.sentryclirc"

# Check required tools
function check_dependencies() {
  for cmd in jq tomlq; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: '$cmd' is required but not installed."
      exit 1
    fi
  done
}

# Load configuration from ~/.sentryclirc
function load_config() {
  ORG_SLUG=$(tomlq -r '.defaults.org' "$CONFIG_FILE")
  PROJECT_ID=$(tomlq -r '.defaults.project' "$CONFIG_FILE")
  BASE_URL=$(tomlq -r '.defaults.url // "https://sentry.io"' "$CONFIG_FILE" | sed 's:/*$::')
  AUTH_TOKEN=$(tomlq -r '.auth.token' "$CONFIG_FILE")

  if [[ -z "$AUTH_TOKEN" || -z "$ORG_SLUG" || -z "$PROJECT_ID" ]]; then
    echo "Missing required values in ~/.sentryclirc"
    exit 1
  fi
}

# Subcommand: monitor-environment-delete <environment>
function monitor_environment_delete() {
  local ENVIRONMENT="$1"
  if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 monitor-environment-delete <environment>"
    exit 1
  fi

  echo "Fetching monitors for organization '$ORG_SLUG' from $BASE_URL..."
  monitors=$(curl -s -H "Authorization: Bearer $AUTH_TOKEN" \
    "$BASE_URL/api/0/organizations/$ORG_SLUG/monitors/?project=$PROJECT_ID" | jq -c '.[]')

  # echo "$monitors" | jq -r '.'

  # Track monitors to delete
  matching_monitors=()

  while read -r monitor; do
    monitor_slug=$(echo "$monitor" | jq -r '.slug')
    monitor_name=$(echo "$monitor" | jq -r '.name')
    monitor_envs=$(echo "$monitor" | jq -r '.environments | .[].name')

    if echo "$monitor_envs" | grep -qx "$ENVIRONMENT"; then
      matching_monitors+=("$monitor_slug")
      echo "→ $monitor_name ($monitor_slug)"
    fi
  done <<< "$monitors"

  if [[ ${#matching_monitors[@]} -eq 0 ]]; then
    echo "No monitors found for environment '$ENVIRONMENT'."
    return
  fi

  echo
  echo "Found ${#matching_monitors[@]} monitor(s) tied to environment '$ENVIRONMENT'."
  read -rp "Do you want to delete them? [y/N]: " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for slug in "${matching_monitors[@]}"; do
      echo "Deleting monitor: $slug"
      curl -s -X DELETE -H "Authorization: Bearer $AUTH_TOKEN" \
        "$BASE_URL/api/0/projects/$ORG_SLUG/$PROJECT_ID/monitors/$slug/?environment=$ENVIRONMENT"
    done
    echo "Deletion complete."
  else
    echo "Aborted. No monitors deleted."
  fi
}

# Main entry point with subcommand handling
function main() {
  check_dependencies
  load_config

  case "$1" in
    monitor-environment-delete)
      shift
      monitor_environment_delete "$@"
      ;;
    *)
      echo "Unknown subcommand: $1"
      echo "Available subcommands:"
      echo "  monitor-environment-delete <environment>"
      exit 1
      ;;
  esac
}

main "$@"
