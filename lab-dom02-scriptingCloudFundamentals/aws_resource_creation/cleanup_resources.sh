#!/bin/bash
# Terminates/deletes every resource created by the other scripts in this
# project, identified via the Project=AutomationLab tag (or, for the key
# pair/bucket, the names recorded during creation).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Using region: ${REGION}"
echo "Cleaning up resources tagged Project=${PROJECT_TAG}..."

# Deletes every object version and delete marker in a versioned bucket
delete_all_object_versions() {
  local bucket="$1"

  local versions
  versions=$(aws s3api list-object-versions --bucket "${bucket}" --region "${REGION}" \
    --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')
  if echo "${versions}" | grep -q '"Key"'; then
    aws s3api delete-objects --bucket "${bucket}" --region "${REGION}" --delete "${versions}" >/dev/null
  fi

  local markers
  markers=$(aws s3api list-object-versions --bucket "${bucket}" --region "${REGION}" \
    --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')
  if echo "${markers}" | grep -q '"Key"'; then
    aws s3api delete-objects --bucket "${bucket}" --region "${REGION}" --delete "${markers}" >/dev/null
  fi
}

# Terminate tagged EC2 instances
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=${PROJECT_TAG}" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --region "${REGION}" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -n "${INSTANCE_IDS}" ]; then
  echo "Terminating instances: ${INSTANCE_IDS}"
  aws ec2 terminate-instances --instance-ids ${INSTANCE_IDS} --region "${REGION}" >/dev/null
  echo "Waiting for instances to terminate..."
  aws ec2 wait instance-terminated --instance-ids ${INSTANCE_IDS} --region "${REGION}"
else
  echo "No tagged instances found."
fi

# Delete the security group (must run after instances are gone)
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" \
  --region "${REGION}" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "None")

if [ -n "${SG_ID}" ] && [ "${SG_ID}" != "None" ]; then
  echo "Deleting security group ${SG_ID}..."
  aws ec2 delete-security-group --group-id "${SG_ID}" --region "${REGION}"
else
  echo "No security group '${SG_NAME}' found."
fi

# Delete the key pair (and local private key file)
if aws ec2 describe-key-pairs --key-names "${KEY_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "Deleting key pair '${KEY_NAME}'..."
  aws ec2 delete-key-pair --key-name "${KEY_NAME}" --region "${REGION}"
  rm -f "${SCRIPT_DIR}/${KEY_FILE}"
else
  echo "No key pair '${KEY_NAME}' found."
fi

# Empty and delete every bucket matching ${BUCKET_PREFIX}-${ACCOUNT_ID}*
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
BUCKET_MATCH_PREFIX="${BUCKET_PREFIX}-${ACCOUNT_ID}"

MATCHING_BUCKETS=$(aws s3api list-buckets \
  --query "Buckets[?starts_with(Name, '${BUCKET_MATCH_PREFIX}')].Name" \
  --output text)

if [ -n "${MATCHING_BUCKETS}" ]; then
  for BUCKET_NAME in ${MATCHING_BUCKETS}; do
    echo "Emptying bucket ${BUCKET_NAME} (all versions)..."
    delete_all_object_versions "${BUCKET_NAME}"
    echo "Deleting bucket ${BUCKET_NAME}..."
    aws s3api delete-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
    echo "Bucket ${BUCKET_NAME} deleted."
  done
  rm -f "${SCRIPT_DIR}/.last_bucket_name"
else
  echo "No buckets found with prefix '${BUCKET_MATCH_PREFIX}'."
fi

echo "Cleanup complete."
