# Automate AWS Resource Creation with Bash

Bash scripts that automate provisioning of an EC2 instance, a security group,
and an S3 bucket via the AWS CLI, plus a script to tear everything back down.

## Files

| File | Purpose |
|---|---|
| `config.sh` | Shared variables (region, tag, names) sourced by every other script. Edit this once to change region/naming for the whole project. |
| `create_ec2.sh` | Creates an EC2 key pair, resolves the latest free-tier Amazon Linux 2 AMI, launches a `t2.micro` instance tagged `Project=AutomationLab`, and prints the instance ID and public IP. |
| `create_security_group.sh` | Creates a `devops-sg` security group in the default VPC, opens inbound TCP 22 (SSH) and TCP 80 (HTTP), and prints the group ID and rules. |
| `create_s3_bucket.sh` | Creates a globally-unique S3 bucket, tags it, enables versioning, blocks public access, applies a policy denying non-TLS requests, and uploads a sample `welcome.txt`. |
| `cleanup_resources.sh` | Terminates the tagged EC2 instance(s), deletes the security group, deletes the key pair (and local `.pem`), and empties + deletes every S3 bucket matching `${BUCKET_PREFIX}-${ACCOUNT_ID}*`. |

## Prerequisites

1. **AWS CLI installed** (v2 recommended):
   ```bash
   aws --version
   ```
2. **Credentials configured**:
   ```bash
   aws configure
   ```
3. **Verify setup**:
   ```bash
   aws sts get-caller-identity
   aws configure list
   ```
   The identity call should return your account ID/ARN, confirming the CLI can authenticate.

The IAM user/role running these scripts needs permissions for EC2 (key pairs,
instances, security groups), SSM (`GetParameter`, to resolve the AMI ID), S3,
and STS (`GetCallerIdentity`).

## Usage

Run scripts from inside `aws_resource_creation/`. All scripts are idempotent
where practical (they reuse an existing key pair/security group instead of
failing if run twice).

```bash
# 1. Open ports before launching the instance so it comes up reachable
./create_security_group.sh

# 2. Launch the EC2 instance (picks up the security group above automatically)
./create_ec2.sh

# 3. Create the S3 bucket and upload the sample file
./create_s3_bucket.sh

# 4. When finished, tear everything down
./cleanup_resources.sh
```

Each script prints a summary block at the end (instance ID/public IP,
security group ID/rules, or bucket name) so you can confirm success.

Screenshots of script output can be found in `screenshots/`, and a flowchart
of the overall process can be found in `flowChart/`.

All resources are tagged `Project=AutomationLab`; `cleanup_resources.sh` uses
that tag (via `--filters`) to find the EC2 instance(s) and security group
safely, so it won't touch unrelated resources in the account. The EC2 key
pair is found by name (`KEY_NAME`). S3 buckets are found by matching the
`${BUCKET_PREFIX}-${ACCOUNT_ID}` prefix, so cleanup removes every bucket this
project has created (each run of `create_s3_bucket.sh` makes a new,
timestamp-suffixed bucket), not just the most recent one.

## Configuration

Edit `config.sh` to change the region, resource names, or tag value used
across all scripts:

```bash
REGION="eu-west-1"
PROJECT_TAG="AutomationLab"
KEY_NAME="devops-lab-key"
INSTANCE_NAME="devops-lab-instance"
INSTANCE_TYPE="t2.micro"
SG_NAME="devops-sg"
BUCKET_PREFIX="devops-lab-bucket"
```

## Challenges faced and how they were resolved

- **AMI IDs are region-specific and change over time.** Hardcoding one would
  break as soon as the region changed or the AMI was deprecated. Resolved by
  looking up the latest Amazon Linux 2 AMI dynamically via the public SSM
  parameter `/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2`.
- **S3 bucket names must be globally unique.** Resolved by suffixing the
  configured prefix with the account ID and a Unix timestamp.
- **Versioned S3 buckets can't be deleted while they still hold object
  versions or delete markers.** `cleanup_resources.sh` explicitly lists and
  deletes every version and delete marker before deleting the bucket itself.
- **Security groups can't be deleted while attached to a running instance.**
  `cleanup_resources.sh` terminates EC2 instances first and waits for
  termination before attempting to delete the security group.
- **Re-running scripts shouldn't fail on already-created resources.** The key
  pair and security group scripts check for an existing resource by name
  before attempting to create one.
- **Each run of `create_s3_bucket.sh` creates a new, uniquely named bucket**
  (timestamp-suffixed), so a single remembered bucket name isn't enough to
  clean up after multiple runs. `cleanup_resources.sh` instead lists all
  buckets in the account and deletes every one matching the
  `${BUCKET_PREFIX}-${ACCOUNT_ID}` prefix.

## Security notes

- SSH (22) and HTTP (80) are opened to `0.0.0.0/0` for lab convenience, per
  the assignment. In a real environment, scope port 22 to a specific IP/CIDR.
- The S3 bucket blocks all public access and denies any request that isn't
  over TLS; it is not made publicly readable.
- The private key (`.pem`) is written with `chmod 400` and should never be
  committed to version control.
