#!/bin/bash
# Creates a security group in the default VPC, opens port 22 (SSH) and
# port 80 (HTTP), and displays the resulting group ID and rules.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Using region: ${REGION}"

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --region "${REGION}" \
  --query "Vpcs[0].VpcId" \
  --output text)

if [ -z "${VPC_ID}" ] || [ "${VPC_ID}" == "None" ]; then
  echo "Error: no default VPC found in region ${REGION}." >&2
  exit 1
fi
echo "Using VPC: ${VPC_ID}"

# Reuse the security group if it already exists so the script is re-runnable
EXISTING_SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
  --region "${REGION}" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "None")

# create security group if it does not already exist
if [ -n "${EXISTING_SG_ID}" ] && [ "${EXISTING_SG_ID}" != "None" ]; then
  echo "Security group '${SG_NAME}' already exists: ${EXISTING_SG_ID}"
  SG_ID="${EXISTING_SG_ID}"
else
  echo "Creating security group '${SG_NAME}'..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "${SG_DESCRIPTION}" \
    --vpc-id "${VPC_ID}" \
    --region "${REGION}" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Project,Value=${PROJECT_TAG}}]" \
    --query "GroupId" \
    --output text)

  echo "Security group created: ${SG_ID}"

  # port opening
  echo "Opening port 22 (SSH)..."
  aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 22 --cidr 0.0.0.0/0 \
    --region "${REGION}" >/dev/null

  echo "Opening port 80 (HTTP)..."
  aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp --port 80 --cidr 0.0.0.0/0 \
    --region "${REGION}" >/dev/null
fi

echo "-----------------------------------"
echo "Security Group ID: ${SG_ID}"
echo "Rules:"
aws ec2 describe-security-groups \
  --group-ids "${SG_ID}" \
  --region "${REGION}" \
  --query "SecurityGroups[0].IpPermissions" \
  --output table
echo "-----------------------------------"
