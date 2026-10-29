#!/usr/bin/env bash
# Keeps the newest <keep> ACTIVE revisions of a task definition family (plus
# any revision a service deployment still uses), deregisters the rest, then
# deletes every INACTIVE revision so they stop counting against the
# account's task definition quota.
#
# Usage: cleanup-taskdefs.sh <cluster> <service> <family> <keep>
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <cluster> <service> <family> <keep>" >&2
  exit 2
fi

cluster="$1" service="$2" family="$3" keep="$4"

# --family-prefix is a prefix match, so filter to this exact family.
list_revisions() {
  aws ecs list-task-definitions --family-prefix "$family" --status "$1" --sort DESC \
    --query 'taskDefinitionArns' --output json |
    jq -r --arg family "$family" '.[] | select(test(":task-definition/\($family):[0-9]+$"))'
}

in_use="$(aws ecs describe-services --cluster "$cluster" --services "$service" \
  --query 'services[0].deployments[].taskDefinition' --output json)"

mapfile -t active < <(list_revisions ACTIVE)
echo "${#active[@]} active revisions of $family, keeping the newest $keep"

for arn in "${active[@]:keep}"; do
  if jq -e --arg arn "$arn" 'index($arn)' <<<"$in_use" >/dev/null; then
    echo "keep (in use)  $arn"
    continue
  fi
  aws ecs deregister-task-definition --task-definition "$arn" >/dev/null
  echo "deregistered   $arn"
done

mapfile -t inactive < <(list_revisions INACTIVE)
# delete-task-definitions takes at most 10 ARNs per call.
for ((i = 0; i < ${#inactive[@]}; i += 10)); do
  aws ecs delete-task-definitions --task-definitions "${inactive[@]:i:10}" \
    --query 'taskDefinitions[].taskDefinitionArn' --output text | tr '\t' '\n' | sed 's/^/deleted        /'
done
