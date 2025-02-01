#!/bin/bash -e


DESTINATION_DIR="/tmp/1password-dumps/kube-configs"
mkdir -p $DESTINATION_DIR

op item list --categories Document --tags k8s/kubeconfig --format=json | jq -c '.[]' | while IFS= read -r item; do
    item_id=$(echo "$item" | jq -r '.id')
    item_title=$(echo "$item" | jq -r '.title')
    echo "------- Pulling: $item_title"
    op document get $item_id --force --out-file="$DESTINATION_DIR/$item_title.yaml"
done
