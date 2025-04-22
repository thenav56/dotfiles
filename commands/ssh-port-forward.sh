#!/bin/bash

CONFIG_FILE="${HOME}/.ssh-forwards.yaml"
PROFILE="$1"

SAMPLE_CONFIG=$(cat <<EOF
defaults:
  host: my-machine-port-forward

profiles:
  timur:
    ports:
      web: 8100:8100
    bookmarks:
      - http://localhost:8100/admin/
EOF
)

if ! [ -f "$CONFIG_FILE" ]; then
  echo "❌ No config file exists at $CONFIG_FILE"
  echo "Create one as required, Sample:"
  echo "$SAMPLE_CONFIG" | yq
  echo ""
  echo "And run using"
  echo "\$ $0 timur"
  exit 1
fi

show_available_profiles() {
  echo "📂 Available profiles:"
  yq '.profiles | keys | .[]' "$CONFIG_FILE" | while read profile; do
    echo " - 🔐 $profile"
  done
}

if [ -z "$PROFILE" ]; then
  echo "📘 Usage: $0 <profile>"
  show_available_profiles
  exit 1
fi

# Check if the profile exists
if ! yq -e ".profiles | has(\"$PROFILE\")" "$CONFIG_FILE" >/dev/null 2>&1; then
  echo "❌ Profile '$PROFILE' not found in config."
  show_available_profiles
  exit 1
fi

# Load defaults
DEFAULT_HOST=$(yq '.defaults.host // ""' "$CONFIG_FILE")

# Load profile-specific host or fallback to default
PROFILE_HOST=$(yq ".profiles.${PROFILE}.host // \"$DEFAULT_HOST\"" "$CONFIG_FILE")

# Check if ports is a mapping or a sequence
PORTS_TYPE=$(yq -r ".profiles.${PROFILE}.ports | type" "$CONFIG_FILE")

if [ -z "$PROFILE_HOST" ] || [ -z "$PORTS_TYPE" ]; then
  echo "⚠️  Profile '$PROFILE' is missing 'host' or 'ports'."
  exit 1
fi

TUNNELS=()

# Function to parse port string and add to TUNNELS
add_tunnel() {
  local PORT="$1"
  local LABEL="$2"

  if [[ "$PORT" == *":"*":"*":"* ]]; then
    LOCAL_ADDR=$(echo "$PORT" | cut -d':' -f1)
    LOCAL_PORT=$(echo "$PORT" | cut -d':' -f2)
    REMOTE_ADDR=$(echo "$PORT" | cut -d':' -f3)
    REMOTE_PORT=$(echo "$PORT" | cut -d':' -f4)
  elif [[ "$PORT" == *":"*":"* ]]; then
    LOCAL_ADDR="localhost"
    LOCAL_PORT=$(echo "$PORT" | cut -d':' -f1)
    REMOTE_ADDR=$(echo "$PORT" | cut -d':' -f2)
    REMOTE_PORT=$(echo "$PORT" | cut -d':' -f3)
  elif [[ "$PORT" == *":"* ]]; then
    LOCAL_ADDR="localhost"
    LOCAL_PORT=$(echo "$PORT" | cut -d':' -f1)
    REMOTE_ADDR="localhost"
    REMOTE_PORT=$(echo "$PORT" | cut -d':' -f2)
  else
    LOCAL_ADDR="localhost"
    LOCAL_PORT="$PORT"
    REMOTE_ADDR="localhost"
    REMOTE_PORT="$PORT"
  fi

  if [ -n "$LABEL" ]; then
      echo "- Adding forward for [🔧 $LABEL]: $LOCAL_ADDR:$LOCAL_PORT -> $REMOTE_ADDR:$REMOTE_PORT"
  else
    echo "- Adding forward: $LOCAL_ADDR:$LOCAL_PORT -> $REMOTE_ADDR:$REMOTE_PORT"
  fi

  TUNNELS+=("-L" "$LOCAL_ADDR:$LOCAL_PORT:$REMOTE_ADDR:$REMOTE_PORT")
}

# Process ports
if [ "$PORTS_TYPE" == "!!map" ]; then
  while IFS=$'\t' read -r SERVICE PORT; do
    add_tunnel "$PORT" "$SERVICE"
  done < <(yq -r ".profiles.${PROFILE}.ports | to_entries[] | [.key, .value] | @tsv" "$CONFIG_FILE")

elif [ "$PORTS_TYPE" == "!!seq" ]; then
  while read -r PORT; do
    add_tunnel "$PORT"
  done < <(yq -r ".profiles.${PROFILE}.ports[]" "$CONFIG_FILE")

else
  echo "❌ Unknown ports format in profile '$PROFILE'. Expected mapping or array. Found: $PORTS_TYPE"
  exit 1
fi

echo ""
echo "⭐ Bookmarks:"
while IFS=$'\t' read -r URL; do
    echo " 🔖 $URL"
done < <(yq -r ".profiles.${PROFILE}.bookmarks[]" "$CONFIG_FILE")

echo ""
echo "🚀 Launching SSH tunnel to 🖥️  $PROFILE_HOST"
echo "🛑 Press Ctrl+C to stop the tunnel."
echo ""

set -x
ssh -N "${TUNNELS[@]}" "$PROFILE_HOST"
