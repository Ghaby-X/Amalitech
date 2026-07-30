# Lab DOM04 - Advanced IaC

Provisions AWS networking and a public EC2 instance with Terraform (composed from shared modules), then uses Ansible with a dynamic AWS inventory to configure it: installs nginx and has it serve a small static site directly.

## Architecture

![Architecture Diagram](./lab-dom04-architecturediagram.png)

**Note:** this diagram predates the module refactor, the split-out key pair, and the switch from a Docker-backed reverse proxy to a static site — it still shows the original shape (Ansible roles → playbook → reverse proxy → app container). The AWS side (VPC → subnet → SG → instance) and the SSH control path are still accurate; the nginx/app layer isn't anymore. See "What changed" below for the current picture.

- **AWS (eu-west-1):** a VPC (`lab-dom04-vpc`) containing one public subnet (`lab-dom04-public-subnet`), a security group scoped to SSH and HTTP only, and a single EC2 instance reachable via its EC2 key pair.
- **Terraform backend (S3):** shared with `lab-dom03-IACWithTerraform` and every `helpers/` config, bucket `terraform-backend-eu-west-1-55zz0s`, each config using its own state `key` (this lab's is `lab-dom04/statefile`).
- **Ansible (control side):** the `nginx` role installs and enables nginx; `site.yml` owns the site-specific parts (which template, which static content) and deploys them.

### What changed from the original design

- **Modules:** `infrastructure/main.tf` no longer declares raw AWS resources directly — it composes `aws_vpc`, `aws_subnet`, `aws_route_table`, `aws_security_group`, and `aws_ec2` from [`helpers/terraform-modules`](../helpers/terraform-modules) (a git submodule).
- **Key pair split out:** the SSH key pair is no longer created by this lab's own `main.tf`. It's managed independently in [`helpers/keypair`](../helpers/keypair), with its own Terraform state, and read here via `data.terraform_remote_state`.
- **Static site instead of reverse proxy + Docker:** nginx now serves plain static files directly (`root`/`index`/`try_files`) instead of proxying to a containerized app. The `docker` role and `site/compose.yml` are still on disk but unused — kept for reference, not referenced from `site.yml`.
- **Dynamic inventory:** `configuration/inventory/aws_ec2.yml` (the `amazon.aws.aws_ec2` plugin) replaces manually editing `inventory.ini`'s IP every time Terraform recreates the instance. The old static `inventory.ini` is still present but superseded — don't use both against the same directory at once.

---

## Project structure

```
lab-dom04-AdvancedIAC/
├── infrastructure/
│   ├── providers.tf       Terraform block, AWS provider, S3 backend (key: lab-dom04/statefile)
│   ├── main.tf            Composes vpc/subnet/route_table/security_group/ec2 modules; reads the key pair via remote state
│   ├── variable.tf        Input variables (no key-pair vars here anymore)
│   ├── outputs.tf         IDs, public IP/DNS, SSH user, key pair name/path (from remote state)
│   └── terraform.tfvars   Your SSH CIDR (gitignored, not committed)
├── configuration/
│   ├── ansible.cfg           Disables SSH host key checking (this lab's EC2 host gets a new IP/key every apply)
│   ├── site.yml              Playbook: applies the nginx role, deploys static site content
│   ├── inventory/
│   │   ├── aws_ec2.yml        Dynamic inventory (amazon.aws.aws_ec2 plugin) - use this
│   │   └── inventory.ini      Old static inventory - superseded, kept for reference only
│   ├── templates/
│   │   └── nginx.conf.j2      Static-file server block, owned by the playbook (not the role)
│   ├── site/
│   │   ├── webroot/           Static site content (index, about, docs/, game.html, 404.html, style.css)
│   │   └── compose.yml        Unused leftover from the old Docker-backed setup
│   └── roles/
│       ├── nginx/          See roles/nginx/README.md
│       └── docker/         Unused, kept on disk; see roles/docker/README.md
├── screenshots/            Proof from the old reverse-proxy setup - stale, needs retaking for the static site
├── lab-dom04-architecturediagram.png
├── APPLY.txt               terraform apply output
├── ansible-play.txt        ansible-playbook run output
└── DESTROY.txt             terraform destroy output
```

Shared, reusable pieces this lab depends on but doesn't own:

```
helpers/
├── terraform-modules/   git submodule (git@github.com:Ghaby-X/terraform-modules.git) - aws_vpc, aws_subnet,
│                        aws_route_table, aws_security_group, aws_ec2, aws_key_pair, aws_nat_gateway
├── keypair/              Standalone Terraform root managing the SSH key pair, own state (helpers/keypair/statefile)
└── terraform-backend/    Creates the shared S3 bucket + lifecycle rule capping state file versions at 3
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Terraform `~> 1.15.8` | Verify with `terraform version` |
| AWS credentials | `aws configure` or env vars |
| Ansible (`ansible` package, not just `ansible-core`) | Needed for the bundled `amazon.aws` collection; verify with `ansible-galaxy collection list amazon.aws` |
| `boto3` / `botocore` | Required by the `amazon.aws.aws_ec2` dynamic inventory plugin; `pip install boto3 botocore` |
| Remote backend already bootstrapped | Same S3 bucket used by `lab-dom03-IACWithTerraform` and every `helpers/` config |
| `helpers/keypair` already applied | Must exist before this lab's `terraform apply`, since `main.tf` reads its outputs via remote state |
| Git submodule initialized | `git submodule update --init helpers/terraform-modules` |

---

## Usage

### 1. Provision the key pair (once, or whenever it doesn't already exist)

```bash
cd ../../helpers/keypair
terraform init
terraform apply
```

This is independent of this lab's own state — only re-run it if the key pair doesn't already exist or you intentionally want to rotate it.

### 2. Provision infrastructure

```bash
cd infrastructure
echo "ssh_allowed_cidr = \"$(curl -s https://checkip.amazonaws.com)/32\"" > terraform.tfvars
terraform init
terraform plan
terraform apply -no-color | tee ../APPLY.txt
```

`-no-color` avoids littering the log file with raw ANSI escape codes. This creates the VPC/subnet/networking and launches the EC2 instance, tagging it so the dynamic inventory can find it.

### 3. Confirm the dynamic inventory finds it

```bash
cd ../configuration
ansible-inventory -i inventory/aws_ec2.yml --graph
```

No manual IP editing needed — `aws_ec2.yml` filters on `tag:Project: lab-dom04-IAC` and `instance-state-name: running`, and derives `ansible_host` live from each matching instance's `public_ip_address`.

### 4. Run the playbook

```bash
ansible-playbook -i inventory/aws_ec2.yml site.yml | tee ../ansible-play.txt
```

This installs and enables nginx (role), then deploys `templates/nginx.conf.j2` and the static content in `site/webroot/` directly to `/usr/share/nginx/html`. `ansible.cfg` disables host key checking in this directory, since the host's IP and SSH key change every time the instance is recreated — there's no long-lived trust to protect on a disposable lab box, and the alternative (`ssh-keyscan` before every run) is friction with no real payoff here.

### 5. Verify

Open the instance's public IP in a browser — you should see the static "Lab DOM04" page, with links to `/about.html`, `/docs/`, and `/game.html`.

```bash
curl http://<instance_public_ip>
```

> The screenshots in `screenshots/` are from the old Docker-backed reverse-proxy setup and no longer match what's actually served — retake them against the static site before relying on them as evidence.

### 6. Destroy

```bash
cd ../infrastructure
terraform destroy -no-color | tee ../DESTROY.txt
```

Run this interactively (not with `-auto-approve`), so you still get Terraform's own "yes" confirmation before it tears down real resources. This does **not** destroy `helpers/keypair` — that's managed separately and meant to persist across applies.

---

## Variables reference

| Variable | Default | Description |
|---|---|---|
| `region` | `eu-west-1` | AWS region |
| `vpc_cidr_block` | `10.0.0.0/16` | CIDR for the VPC |
| `vpc_name` | `lab-dom04-vpc` | Name tag for the VPC |
| `subnet_cidr_block` | `10.0.1.0/24` | CIDR for the public subnet |
| `subnet_name` | `lab-dom04-public-subnet` | Name tag for the subnet |
| `igw_name` | `lab-dom04-igw` | Name tag for the Internet Gateway (created by the `aws_vpc` module) |
| `rt_name` | `lab-dom04-rt` | Name tag for the route table |
| `rt_association_ipv4_igw_cidr_block` | `0.0.0.0/0` | IPv4 default route CIDR |
| `rt_association_ipv6_igw_cidr_block` | `::/0` | Unused since the module refactor - the shared `aws_route_table` module only supports IPv4 routes, and this was already inert (no IPv6 CIDR assigned anywhere in the VPC) |
| `sg_name` | `allow_tls_ssh` | Name tag for the security group |
| `ssh_allowed_cidr` | *(required, no default)* | CIDR allowed to SSH on port 22, set via `terraform.tfvars` |
| `http_allowed_cidr` | `0.0.0.0/0` | CIDR allowed on port 80, and reused for the all-outbound egress rule |
| `instance_type` | `t3.micro` | EC2 instance type |
| `instance_name` | `lab-dom04-web` | Name tag for the EC2 instance |

Key-pair variables (`key_name`, `private_key_path`) now live in [`helpers/keypair/variables.tf`](../helpers/keypair/variables.tf), not here.

---

## Outputs reference

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `public_subnet_id` | ID of the public subnet |
| `security_group_id` | ID of the security group |
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Public IP of the EC2 instance |
| `instance_public_dns` | Public DNS name of the EC2 instance |
| `ssh_user` | SSH user for the instance (`ec2-user`, Amazon Linux default) |
| `key_pair_name` | Name of the AWS key pair, read from `helpers/keypair`'s remote state |
| `private_key_path` | Local path to the private key file, read from `helpers/keypair`'s remote state |

---

## Ansible configuration notes

- `nginx_template` and `nginx_site_conf_path` are owned entirely by `site.yml`, not by the `nginx` role. See `roles/nginx/README.md` for why (it comes down to `include_vars` outranking playbook `vars:` in Ansible's precedence order).
- The `nginx` role only has a verified `vars/RedHat.yml` (Amazon Linux 2023); Debian/Ubuntu support was removed.
- nginx serves static files directly (`root` + `index` + `try_files` in `templates/nginx.conf.j2`) — there's no reverse proxy and no backend process for it to depend on.
- The `docker` role and `site/compose.yml` are unused but intentionally left on disk, not deleted.
- The dynamic inventory plugin (`amazon.aws.aws_ec2`) emits a deprecation warning about its own legacy `tags` host variable on every run — that's unconditional plugin behavior, not something our config triggers, and it's harmless since nothing here reads that variable (we use `ec2_tags` instead, e.g. in `keyed_groups`).
