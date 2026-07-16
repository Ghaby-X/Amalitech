#!/bin/bash
# Shared configuration sourced by every script in this project.

REGION="eu-west-1"
PROJECT_TAG="AutomationLab"

# EC2
KEY_NAME="devops-lab-key"
KEY_FILE="${KEY_NAME}.pem"
INSTANCE_NAME="devops-lab-instance"
INSTANCE_TYPE="t3.micro"

# Security group
SG_NAME="devops-sg"
SG_DESCRIPTION="DevOps automation lab SG - SSH (22) and HTTP (80)"

# S3
BUCKET_PREFIX="devops-lab-bucket"
