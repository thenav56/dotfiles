#!/bin/bash -e

DESTINATION_DIR="/tmp/1password-dumps/kube-configs"
mkdir -p "$DESTINATION_DIR"

# Define the function to download a single document
download_document() {
  item_json="$1"
  item_id=$(echo "$item_json" | jq -r '.id')
  item_title=$(echo "$item_json" | jq -r '.title')
  output_file="$DESTINATION_DIR/$item_title.yaml"
  op document get "$item_id" --force --out-file="$output_file" > /dev/null 2>&1
  echo "✅ $item_title -> $output_file"
}

export -f download_document
export DESTINATION_DIR  # export the variable so the function can access it

echo "⬇️ Pulling....."
# Parallel-safe version
op item list --categories Document --tags k8s/kubeconfig --format=json | \
  jq -c '.[]' | \
  while IFS= read -r line; do
    printf '%s\0' "$line"
  done | \
  xargs -0 -n1 -P5 bash -c 'download_document "$0"'
