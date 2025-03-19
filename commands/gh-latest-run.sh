#!/bin/bash -ex

CURRENT_BRANCH="${CURRENT_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"
WORKFLOW_FILE="${1?error}"

LATEST_RUN_ID=$(gh run list --workflow "$WORKFLOW_FILE" --branch "${CURRENT_BRANCH}" --json 'databaseId' --jq '.[0].databaseId')

gh run view "$LATEST_RUN_ID"
