#!/usr/bin/env bash
# Copies the sandbox `pipeline_config` Terraform output into the GitHub
# environment's variables, so the workflow deploys to whatever Terraform
# actually created. Re-run after any apply that changes those outputs.
#
# Usage: sync-github-env.sh [environment] [repository]
set -euo pipefail

environment="${1:-sandbox}"
repo="${2:-Ghaby-X/Amalitech}"
tf_dir="$(dirname "$0")/../terraform/environments/$environment"

terraform -chdir="$tf_dir" output -json pipeline_config |
  jq -r 'to_entries[] | "\(.key)\t\(.value)"' |
  while IFS=$'\t' read -r name value; do
    gh variable set "$name" --env "$environment" --repo "$repo" --body "$value"
  done
