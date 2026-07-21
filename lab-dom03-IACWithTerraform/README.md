# Lab DOM03 - IaC with Terraform

Provisions foundational AWS networking and a public EC2 instance with Terraform, backed by a remote S3 state store and DynamoDB state locking.

## Architecture

![Architecture Diagram](./lab-dom03-architecture.png)

The lab creates a self-contained VPC with one public subnet, an Internet Gateway, and a single EC2 web instance, all wired together with a route table and security group.

```
AWS (eu-west-1)
└── VPC  10.0.0.0/16
    └── Public Subnet  10.0.1.0/24
        ├── Internet Gateway  (default IPv4/IPv6 routes)
        ├── Security Group    SSH :22 (your IP) | HTTP :80 (0.0.0.0/0)
        └── EC2 t3.micro      Amazon Linux 2023, Apache httpd
```

Remote backend (provisioned separately in `../helpers/terraform-backend`):

```
S3 bucket  terraform-backend-eu-west-1-55zz0s   <- state file
DynamoDB   terraform-locks                        <- lock table
```

---

## Project structure

```
lab-dom03-IACWithTerraform/
├── main.tf           Provider, backend config, and all AWS resources
├── variable.tf       Input variables (region, CIDRs, naming, instance type)
├── outputs.tf        VPC/subnet/SG/instance IDs and public IP
├── terraform.tfvars  Your SSH CIDR (gitignored, not committed)
└── screenshots/      Evidence screenshots (plan, apply, destroy, console)
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Terraform `~> 1.15.8` | Verify with `terraform version` |
| AWS credentials | `aws configure` or env vars (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |
| Remote backend already bootstrapped | Run `../helpers/terraform-backend` first if the S3 bucket and DynamoDB table don't exist yet |

---

## Remote backend setup

The S3 bucket and DynamoDB lock table cannot be created by the same Terraform config that uses them as a backend, because a backend can't bootstrap itself. They are provisioned separately:

```
helpers/terraform-backend/
├── main.tf     Creates the S3 bucket (versioned, encrypted, private) and DynamoDB table
├── variable.tf bucket-prefix, region, dynamodb-name
└── outputs.tf  Bucket name and DynamoDB table name
```

The backend config in `main.tf` is hardcoded (backend blocks can't reference variables):

```hcl
backend "s3" {
  bucket         = "terraform-backend-eu-west-1-55zz0s"
  key            = "lab-dom03/statefile"
  region         = "eu-west-1"
  dynamodb_table = "terraform-locks"
}
```

Backend proof:

| Resource | Screenshot |
|---|---|
| S3 bucket | ![S3 bucket](./screenshots/terraform_s3_bucket.png) |
| DynamoDB lock table | ![DynamoDB table](./screenshots/terraform_backend_dynamodb.png) |

---

## Resources defined

### VPC (`aws_vpc.main`)

```hcl
cidr_block = "10.0.0.0/16"
```

A dedicated VPC for the lab. All other resources live inside it.

![VPC proof](./screenshots/terraform_vpc_proof.png)

### Public Subnet (`aws_subnet.public`)

```hcl
cidr_block              = "10.0.1.0/24"
map_public_ip_on_launch = true
```

`map_public_ip_on_launch = true` means any instance launched in this subnet automatically gets a public IP, with no need to allocate an Elastic IP.

![Subnet proof](./screenshots/terraform_subnet_proof.png)

### Internet Gateway + Route Table

```hcl
# Internet Gateway attached to the VPC
resource "aws_internet_gateway" "gw" { ... }

# Route table: default IPv4 and IPv6 routes to the IGW
resource "aws_route_table" "rt" {
  route { cidr_block = "0.0.0.0/0"  gateway_id = aws_internet_gateway.gw.id }
  route { ipv6_cidr_block = "::/0"  gateway_id = aws_internet_gateway.gw.id }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "rt_association" { ... }
```

The route table sends all IPv4 and IPv6 traffic to the Internet Gateway, then it is explicitly associated with the public subnet.

![IGW proof](./screenshots/lab-dom03-igw-proof.png)

### Security Group (`aws_security_group.allow_tls`)

| Direction | Port | Protocol | Source |
|---|---|---|---|
| Inbound | 22 (SSH) | TCP | Your IP (`ssh_allowed_cidr`) |
| Inbound | 80 (HTTP) | TCP | `0.0.0.0/0` |
| Outbound | All | All | `0.0.0.0/0` |

```hcl
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = [var.ssh_allowed_cidr]   # set via terraform.tfvars
}

ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

![Security group proof](./screenshots/lab-dom03-sg-proof.png)

### EC2 Instance (`aws_instance.web`)

```hcl
ami           = data.aws_ami.amazon_linux.id   # latest Amazon Linux 2023 (x86_64, HVM)
instance_type = var.instance_type              # t3.micro
subnet_id     = aws_subnet.public.id
associate_public_ip_address = true
```

A `data` source dynamically resolves the latest `al2023-ami-*-x86_64` AMI from Amazon, so the config never hardcodes an AMI ID that goes stale. A `user_data` script installs and starts Apache httpd and drops a welcome page at `/var/www/html/index.html`.

![EC2 instance console](./screenshots/created_ec2_instance.png)

---

## Usage

### 1. Set your SSH CIDR

Don't open port 22 to `0.0.0.0/0`. Restrict it to your own IP:

```bash
echo "ssh_allowed_cidr = \"$(curl -s https://checkip.amazonaws.com)/32\"" > terraform.tfvars
```

### 2. Init

Downloads the AWS provider and configures the S3 backend:

```bash
terraform init
```

### 3. Plan

Produces an execution plan showing every resource Terraform will create. Review this before applying:

```bash
terraform plan
```

Plan screenshots:

| | |
|---|---|
| ![plan 1](./screenshots/terraform_plan_001.png) | ![plan 2](./screenshots/terraform_plan_002.png) |
| ![plan 3](./screenshots/terraform_plan_003.png) | ![plan 4](./screenshots/terraform_plan_004.png) |
| ![plan 5](./screenshots/terraform_plan_005.png) | ![plan 6](./screenshots/terraform_plan_006.png) |

### 4. Apply

Creates all resources. Terraform acquires a DynamoDB lock for the duration of the operation:

```bash
terraform apply
```

![terraform apply](./screenshots/terraform_apply.png)

After apply, Terraform prints the declared outputs:

```
Outputs:

instance_id         = "i-xxxxxxxxxxxxxxxxx"
instance_public_ip  = "x.x.x.x"
public_subnet_id    = "subnet-xxxxxxxxxxxxxxxxx"
security_group_id   = "sg-xxxxxxxxxxxxxxxxx"
vpc_id              = "vpc-xxxxxxxxxxxxxxxxx"
```

### 5. Verify

Open the instance's public IP in a browser. The Apache welcome page should be served on port 80.

Connect over SSH (using the CIDR you set):

```bash
ssh ec2-user@<instance_public_ip>
```

Or use EC2 Instance Connect from the AWS Console.

### 6. Destroy

Tears down every resource created by this config:

```bash
terraform destroy
```

Destroy screenshots:

| | |
|---|---|
| ![destroy 1](./screenshots/lab-dom03-terraform-destroy-001.png) | ![destroy 2](./screenshots/lab-dom03-terraform-destroy-002.png) |
| ![destroy 3](./screenshots/lab-dom03-terraform-destroy-003.png) | ![destroy 4](./screenshots/lab-dom03-terraform-destroy-004.png) |
| ![destroy 5](./screenshots/lab-dom03-terraform-destroy-005.png) | ![destroy 6](./screenshots/lab-dom03-terraform-destroy-006.png) |
| ![destroy 7](./screenshots/lab-dom03-terraform-destroy-007.png) | |

> The remote backend resources (S3 bucket and DynamoDB table) are **not** destroyed by this command. They are managed by `../helpers/terraform-backend` and are intentionally left running to preserve state history.

---

## Variables reference

| Variable | Default | Description |
|---|---|---|
| `region` | `eu-west-1` | AWS region |
| `vpc_cidr_block` | `10.0.0.0/16` | CIDR for the VPC |
| `vpc_name` | `lab-dom03-vpc` | Name tag for the VPC |
| `subnet_cidr_block` | `10.0.1.0/24` | CIDR for the public subnet |
| `subnet_name` | `lab-dom03-public-subnet` | Name tag for the subnet |
| `igw_name` | `lab-dom03-igw` | Name tag for the Internet Gateway |
| `rt_name` | `lab-dom03-rt` | Name tag for the route table |
| `rt_association_ipv4_igw_cidr_block` | `0.0.0.0/0` | IPv4 default route CIDR |
| `rt_association_ipv6_igw_cidr_block` | `::/0` | IPv6 default route CIDR |
| `ssh_allowed_cidr` | `0.0.0.0/0` | CIDR allowed to SSH on port 22 (**override this**) |
| `instance_type` | `t3.micro` | EC2 instance type |
| `instance_name` | `lab-dom03-web` | Name tag for the EC2 instance |

---

## Outputs reference

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `public_subnet_id` | ID of the public subnet |
| `security_group_id` | ID of the security group |
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Public IP address of the EC2 instance |

---

## Tools

```
$ terraform version
Terraform v1.15.8
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v6.x.x
```
