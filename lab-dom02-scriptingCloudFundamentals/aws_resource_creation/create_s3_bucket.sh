#!/bin/bash
# Creates a uniquely named S3 bucket, enables versioning, applies a bucket
# policy that denies non-TLS requests, and uploads a sample welcome.txt file.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Using region: ${REGION}"

# get account details and generate account unique name
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
BUCKET_NAME="${BUCKET_PREFIX}-${ACCOUNT_ID}-$(date +%s)"

# create s3 bucket
echo "Creating bucket: ${BUCKET_NAME}"
if [ "${REGION}" == "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" >/dev/null
else
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}" >/dev/null
fi

# tag bucket for easy cleanup
aws s3api put-bucket-tagging \
  --bucket "${BUCKET_NAME}" \
  --tagging "TagSet=[{Key=Project,Value=${PROJECT_TAG}}]" \
  --region "${REGION}"

# version bucket
echo "Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled \
  --region "${REGION}"

# blocking public access
echo "Blocking public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --region "${REGION}"

echo "Applying bucket policy (deny non-TLS requests)..."
POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceTLSOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ],
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    }
  ]
}
EOF
)

# attach bucket policy
aws s3api put-bucket-policy \
  --bucket "${BUCKET_NAME}" \
  --policy "${POLICY}" \
  --region "${REGION}"

# upload sample file
echo "Uploading sample file..."
SAMPLE_FILE="${SCRIPT_DIR}/welcome.txt"
if [ ! -f "${SAMPLE_FILE}" ]; then
  echo "Welcome to the AutomationLab S3 bucket!" > "${SAMPLE_FILE}"
fi
aws s3api put-object \
  --bucket "${BUCKET_NAME}" \
  --key "welcome.txt" \
  --body "${SAMPLE_FILE}" \
  --region "${REGION}" >/dev/null

echo "-----------------------------------"
echo "Bucket created: ${BUCKET_NAME}"
echo "Versioning:     Enabled"
echo "Sample file:    welcome.txt uploaded"
echo "-----------------------------------"
