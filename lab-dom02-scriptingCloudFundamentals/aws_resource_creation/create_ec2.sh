#!/bin/bash
# Creates an EC2 key pair and launches a free-tier Amazon Linux 2 instance,
# tagged with Project=AutomationLab. Prints the instance ID and public IP.
set -euo pipefail

# sourcing config.sh for shared config variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Using region: ${REGION}"

# Create the key pair (skip if it already exists so the script is re-runnable)
if aws ec2 describe-key-pairs --key-names "${KEY_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "Key pair '${KEY_NAME}' already exists. Skipping creation."
else
  echo "Creating key pair '${KEY_NAME}'..."
  aws ec2 create-key-pair \
    --key-name "${KEY_NAME}" \
    --region "${REGION}" \
    --query "KeyMaterial" \
    --output text > "${SCRIPT_DIR}/${KEY_FILE}"
  chmod 400 "${SCRIPT_DIR}/${KEY_FILE}"
  echo "Private key saved to ${KEY_FILE}"
fi

# Resolve the latest free-tier Amazon Linux 2 AMI for the region via SSM,
# so the script never relies on a stale hardcoded AMI ID.
echo "Looking up latest Amazon Linux 2 AMI..."
AMI_ID=$(aws ssm get-parameter \
  --name "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2" \
  --region "${REGION}" \
  --query "Parameter.Value" \
  --output text)
echo "Using AMI: ${AMI_ID}"

# Look up the security group created by create_security_group.sh, if present
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${SG_NAME}" \
  --region "${REGION}" \
  --query "SecurityGroups[0].GroupId" \
  --output text 2>/dev/null || echo "None")

# Launch the instance
echo "Launching EC2 instance..."
if [ -n "${SG_ID}" ] && [ "${SG_ID}" != "None" ]; then
  echo "Using security group: ${SG_ID}"
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --security-group-ids "${SG_ID}" \
    --region "${REGION}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Project,Value=${PROJECT_TAG}},{Key=Name,Value=${INSTANCE_NAME}}]" \
    --query "Instances[0].InstanceId" \
    --output text)
else
  echo "Warning: security group '${SG_NAME}' not found. Run create_security_group.sh first for SSH/HTTP access. Launching with the account's default security group instead."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_NAME}" \
    --region "${REGION}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Project,Value=${PROJECT_TAG}},{Key=Name,Value=${INSTANCE_NAME}}]" \
    --query "Instances[0].InstanceId" \
    --output text)
fi

echo "Instance created: ${INSTANCE_ID}"
echo "Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}" --region "${REGION}"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${REGION}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo -e "\n\n-----------------------------------"
echo "Instance ID: ${INSTANCE_ID}"
echo "Public IP:   ${PUBLIC_IP}"
echo "-----------------------------------"
