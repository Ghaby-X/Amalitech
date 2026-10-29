#!/usr/bin/env bash
# Writes a JSON snapshot of the service after a deployment: which revision
# and image are running, task health, load balancer target health and the
# state of every alarm for the environment. Archived with the run as proof
# of the ECS service update.
#
# Usage: collect-deploy-evidence.sh <cluster> <service> <alarm-prefix>
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 <cluster> <service> <alarm-prefix>" >&2
  exit 2
fi

cluster="$1" service="$2" alarm_prefix="$3"

svc="$(aws ecs describe-services --cluster "$cluster" --services "$service" \
  --query 'services[0]' --output json)"
taskdef_arn="$(jq -r '.taskDefinition' <<<"$svc")"
target_group_arn="$(jq -r '.loadBalancers[0].targetGroupArn' <<<"$svc")"

taskdef="$(aws ecs describe-task-definition --task-definition "$taskdef_arn" \
  --query 'taskDefinition' --output json)"

mapfile -t task_arns < <(aws ecs list-tasks --cluster "$cluster" --service-name "$service" \
  --query 'taskArns' --output json | jq -r '.[]')
if [[ ${#task_arns[@]} -gt 0 ]]; then
  tasks="$(aws ecs describe-tasks --cluster "$cluster" --tasks "${task_arns[@]}" \
    --query 'tasks' --output json)"
else
  tasks='[]'
fi

targets="$(aws elbv2 describe-target-health --target-group-arn "$target_group_arn" \
  --query 'TargetHealthDescriptions' --output json)"
alarms="$(aws cloudwatch describe-alarms --alarm-name-prefix "$alarm_prefix" \
  --query 'MetricAlarms' --output json)"

jq -n \
  --arg collectedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson svc "$svc" --argjson taskdef "$taskdef" --argjson tasks "$tasks" \
  --argjson targets "$targets" --argjson alarms "$alarms" '
{
  collectedAt: $collectedAt,
  service: {
    name: $svc.serviceName,
    taskDefinition: $svc.taskDefinition,
    desiredCount: $svc.desiredCount,
    runningCount: $svc.runningCount,
    deployments: [$svc.deployments[] | {id, status, rolloutState, taskDefinition, desiredCount, runningCount, failedTasks, createdAt, updatedAt}],
    alarmRollback: $svc.deploymentConfiguration.alarms,
    circuitBreaker: $svc.deploymentConfiguration.deploymentCircuitBreaker,
    recentEvents: [$svc.events[:10][] | {createdAt, message}]
  },
  taskDefinition: {
    family: $taskdef.family,
    revision: $taskdef.revision,
    image: $taskdef.containerDefinitions[0].image,
    registeredAt: $taskdef.registeredAt
  },
  tasks: [$tasks[] | {taskArn, taskDefinitionArn, lastStatus, healthStatus, availabilityZone, startedAt}],
  targetHealth: [$targets[] | {id: .Target.Id, port: .Target.Port, state: .TargetHealth.State}],
  alarms: [$alarms[] | {name: .AlarmName, state: .StateValue, updatedAt: .StateUpdatedTimestamp}]
}'
