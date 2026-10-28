#!/usr/bin/env bash
# Renders ecs/taskdef.template.json into a task definition ready for
# `aws ecs register-task-definition --cli-input-json file://<output>`.
#
# Usage: render-taskdef.sh <image-ref> <output-file>
#
# <image-ref> should be the pushed image pinned by digest
# (<repo-url>@sha256:...), so ECS runs exactly the image that was scanned.
# Every other value comes from the environment, using the key names of the
# sandbox `pipeline_config` Terraform output.
#
# Terraform renders the same template (via templatefile) for the initial
# revision, so this file is the single definition of what the service runs.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <image-ref> <output-file>" >&2
  exit 2
fi

export IMAGE="$1"
output="$2"
template="$(dirname "$0")/../ecs/taskdef.template.json"

vars=(
  IMAGE TASK_FAMILY TASK_CPU TASK_MEMORY EXECUTION_ROLE_ARN TASK_ROLE_ARN
  CONTAINER_NAME CONTAINER_PORT HEALTH_CHECK_PATH LOG_GROUP AWS_REGION
)

missing=()
for v in "${vars[@]}"; do
  [[ -n "${!v:-}" ]] || missing+=("$v")
done
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "error: missing required variables: ${missing[*]}" >&2
  exit 1
fi

if ! [[ "$CONTAINER_PORT" =~ ^[0-9]+$ ]]; then
  echo "error: CONTAINER_PORT must be a number, got '$CONTAINER_PORT'" >&2
  exit 1
fi

# Only substitute the listed variables, so a stray $ elsewhere in the
# template can never be swapped for something from the runner's environment.
shell_format="$(printf '${%s} ' "${vars[@]}")"
rendered="$(envsubst "$shell_format" < "$template")"

if grep -q '\${' <<<"$rendered"; then
  echo "error: unrendered placeholders remain:" >&2
  grep -o '\${[A-Za-z_]*}' <<<"$rendered" | sort -u >&2
  exit 1
fi

mkdir -p "$(dirname "$output")"
# jq both validates the JSON and normalises the formatting.
jq . <<<"$rendered" > "$output"
echo "rendered $output (image: $IMAGE)"
