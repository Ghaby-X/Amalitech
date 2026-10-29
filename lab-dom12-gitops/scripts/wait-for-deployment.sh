#!/usr/bin/env bash
# Follows the ECS deployment for one task definition revision until it
# completes or fails. Exits non-zero if the deployment circuit breaker or a
# deployment alarm rolled it back, or if it doesn't finish in time.
#
# `aws ecs wait services-stable` isn't enough on its own: after a rollback
# the service is stable again - just on the previous revision.
#
# Usage: wait-for-deployment.sh <cluster> <service> <task-definition-arn> [timeout-seconds]
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: $0 <cluster> <service> <task-definition-arn> [timeout-seconds]" >&2
  exit 2
fi

cluster="$1" service="$2" taskdef="$3" timeout="${4:-900}"
deadline=$((SECONDS + timeout))

recent_events() {
  jq -r '.events[:10][] | "  \(.createdAt)  \(.message)"' <<<"$1"
}

while :; do
  svc="$(aws ecs describe-services --cluster "$cluster" --services "$service" \
    --query 'services[0]' --output json)"
  dep="$(jq -c --arg td "$taskdef" 'first(.deployments[] | select(.taskDefinition == $td)) // empty' <<<"$svc")"

  if [[ -z "$dep" ]]; then
    echo "error: no deployment for $taskdef on $service - it was replaced or rolled back" >&2
    recent_events "$svc" >&2
    exit 1
  fi

  state="$(jq -r '.rolloutState' <<<"$dep")"
  jq -r --arg now "$(date -u +%H:%M:%S)" \
    '"\($now) rollout=\(.rolloutState) desired=\(.desiredCount) running=\(.runningCount) pending=\(.pendingCount) failed=\(.failedTasks)"' <<<"$dep"

  case "$state" in
    COMPLETED)
      echo "deployment of $taskdef completed"
      exit 0
      ;;
    FAILED)
      echo "error: deployment failed: $(jq -r '.rolloutStateReason' <<<"$dep")" >&2
      recent_events "$svc" >&2
      exit 1
      ;;
  esac

  if (( SECONDS >= deadline )); then
    echo "error: deployment still $state after ${timeout}s" >&2
    recent_events "$svc" >&2
    exit 1
  fi
  sleep 15
done
