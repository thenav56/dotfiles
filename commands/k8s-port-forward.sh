#!/bin/bash

if ! command -v yq &>/dev/null; then
  echo "yq is required but not installed. Install it from https://github.com/mikefarah/yq/"
  exit 1
fi

if ! command -v kubie &>/dev/null; then
  echo "kubie is required but not installed. Install it from https://github.com/sbstp/kubie/"
  exit 1
fi


PORTS_FORWARD_PIDS=()
CONFIG_FILE="$HOME/.k8s-forwards.yaml"
PROFILE="$1"

SAMPLE_CONFIG=$(cat <<EOF
profiles:
  timur:
    context: timur
    secrets:
      grafana:
        namespace: monitoring
        secret: monitoring-kube-prometheus-stack-grafana
      argocd:
        namespace: argocd
        secret: argocd-initial-admin-secret
    ports:
      grafana:
        namespace: monitoring
        service: monitoring-kube-prometheus-stack-grafana
        port: 80
        localPort: 8080
      argocd:
        namespace: argocd
        service: argo-cd-argocd-server
        port: 80
        localPort: 8070
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

cleanup() {
  echo ""
  echo "🛑 Caught exit signal. Stopping port-forwards..."
  for pid in "${PORTS_FORWARD_PIDS[@]}"; do
    kill "$pid" 2>/dev/null && echo "  🔻 Killed port-forward process $pid"
  done
  exit 0
}

trap cleanup SIGINT SIGTERM

context=$(yq e ".profiles.\"$PROFILE\".context" "$CONFIG_FILE")
echo "🔹 Profile: $PROFILE (context: $context)"

# Handle secrets
secret_count=$(yq e ".profiles.\"$PROFILE\".secrets | length" "$CONFIG_FILE")
if [[ $secret_count -gt 0 ]]; then
echo "🔐 Secrets:"
secret_keys=$(yq e ".profiles.\"$PROFILE\".secrets | keys | .[]" "$CONFIG_FILE")
for secret_key in $secret_keys; do
  ns=$(yq e ".profiles.\"$PROFILE\".secrets.\"$secret_key\".namespace" "$CONFIG_FILE")
  secret_name=$(yq e ".profiles.\"$PROFILE\".secrets.\"$secret_key\".secret" "$CONFIG_FILE")

  echo "  ▶️ ($secret_key) Decoding secret: $secret_key (secret=$secret_name) (namespace=$ns)"

  kubie exec "$context" "$ns" -- \
    kubectl get secret "$secret_name" -o json |
    jq --color-output -r '.data | with_entries(.value |= @base64d)' | sed 's/^/   /'

  echo ""
done
fi

# Handle ports
port_count=$(yq e ".profiles.\"$PROFILE\".ports | length" "$CONFIG_FILE")
if [[ $port_count -gt 0 ]]; then
echo "🔌 Port Forwarding:"
port_keys=$(yq e ".profiles.\"$PROFILE\".ports | keys | .[]" "$CONFIG_FILE")
for port_key in $port_keys; do
  ns=$(yq e ".profiles.\"$PROFILE\".ports.\"$port_key\".namespace" "$CONFIG_FILE")
  svc=$(yq e ".profiles.\"$PROFILE\".ports.\"$port_key\".service" "$CONFIG_FILE")
  port=$(yq e ".profiles.\"$PROFILE\".ports.\"$port_key\".port" "$CONFIG_FILE")
  localPort=$(yq e ".profiles.\"$PROFILE\".ports.\"$port_key\".localPort" "$CONFIG_FILE")

  echo "  🔄 ($port_key) Forwarding $localPort -> $svc:$port in (namespace=$ns)"
  echo "    -> http://localhost:$localPort"

  kubie exec "$context" "$ns" -- \
    kubectl port-forward service/"$svc" "$localPort":"$port" &
  pid=$!
  PORTS_FORWARD_PIDS+=("$pid")

done
fi

echo ""

echo "✅ Port-forwards are running in background."

wait
