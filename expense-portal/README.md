# Expense Portal — AWS Infrastructure as Code (Terraform)

Modular, multi-environment Terraform that provisions the AWS foundation — **VPC, EKS, RDS, ECR** — for the Expense Portal platform and the Kubernetes portfolio projects (ShopKart, FinLedger, PanelPulse, RatingsBoard) that run on it.

This is the **capstone** for a full Terraform learning phase: it composes remote state, modules, `for_each`, lifecycle rules, dynamic blocks, and multi-environment structure into a single realistic project.

> **Note:** This was authored and **structurally validated** (HCL structure + cross-references). Run `terraform fmt`, `terraform validate`, and `terraform plan` in your own AWS account to fully verify — see the workflow below. Provider/module versions pinned; adjust to current releases as needed.

---

## Architecture

```
bootstrap/                 # creates the S3 remote-state bucket (run once, first)
modules/
  vpc/                     # VPC, public/private subnets per AZ, IGW, NAT, routes
  eks/                     # EKS cluster + managed node group + OIDC (IRSA)
  rds/                     # PostgreSQL, subnet group, security group (dynamic ingress)
  ecr/                     # one repo per service, scan-on-push, lifecycle policy
environments/
  dev/                     # thin root: calls modules with DEV values, own state
  prod/                    # thin root: calls modules with PROD values, own state
```

Thin per-environment root modules call the same four shared modules with different inputs. Each environment has **its own remote state** (separate `key` in the S3 backend) for isolation and limited blast radius. The VPC module's outputs (`vpc_id`, `private_subnet_ids`, `vpc_cidr`) feed the EKS and RDS modules — composition via inputs/outputs.

---

## How each learned concept shows up

| Concept | Where |
|---|---|
| **Remote state + locking** (T2) | `bootstrap/` creates a versioned, encrypted, private S3 bucket; each env uses an S3 backend with `use_lockfile = true` |
| **Variables / tfvars / outputs** (T3) | Every module has a typed, validated `variables.tf` and `outputs.tf`; envs use `dev.tfvars` / `prod.tfvars` |
| **Data sources** (T3) | EKS module reads IAM policy docs and the OIDC TLS cert via `data` blocks |
| **`for_each`** (T4) | Subnets per AZ, ECR repos per service, EKS node IAM policy attachments |
| **`count` (conditional)** (T4) | NAT gateways: one shared (dev) vs one per AZ (prod) |
| **`lifecycle`** (T4) | `prevent_destroy` on the RDS instance and state bucket; `ignore_changes` on EKS `desired_size` (autoscaler owns it) |
| **Modules** (T5) | Four reusable child modules with clean input/output interfaces, called by thin env roots |
| **Functions / dynamic blocks** (T6) | `merge()` for tags, `cidrsubnet()` for subnet math, `jsonencode()` for the ECR policy, a `dynamic "ingress"` block in RDS |
| **Multi-env structure** (T5/T6) | Separate root modules + separate state per environment (preferred over workspaces) |

---

## Prerequisites

- Terraform >= 1.5 (or OpenTofu — same commands as `tofu`)
- AWS CLI configured with credentials
- An AWS account (this creates **real, billable** resources — EKS + RDS + NAT are not free-tier; tear down when done)

---

## Workflow

### 1. Bootstrap the state bucket (once)

```bash
cd bootstrap
terraform init
terraform apply -var 'state_bucket_name=<your-globally-unique-bucket>'
# note the output bucket name
```

### 2. Point each environment at that bucket

In `environments/dev/main.tf` and `environments/prod/main.tf`, replace
`bucket = "REPLACE-with-your-state-bucket"` with your bucket name.

### 3. Provision an environment

```bash
cd environments/dev
export TF_VAR_db_password='<a-strong-password>'   # never commit secrets
terraform init          # installs providers + modules, configures S3 backend
terraform fmt -check    # formatting (exam: fmt)
terraform validate      # config validity, no API calls (exam: validate)
terraform plan  -var-file=dev.tfvars    # review — read it carefully
terraform apply -var-file=dev.tfvars
```

### 4. Connect kubectl and deploy the portfolio

```bash
aws eks update-kubeconfig --name expense-portal-dev-eks --region ap-south-1
kubectl get nodes
# then deploy the Kubernetes portfolio (ShopKart/FinLedger/PanelPulse/RatingsBoard)
```

### 5. Tear down (avoid ongoing charges)

```bash
terraform destroy -var-file=dev.tfvars
# Note: RDS has prevent_destroy — remove that lifecycle rule first if you truly
# intend to delete it, or the destroy will (intentionally) error.
```

---

## Secret handling (important)

The RDS password is a `sensitive` variable supplied via `TF_VAR_db_password` — **never committed**. In a real deployment, source it from AWS Secrets Manager (via a data source) or use Terraform's newer **ephemeral values / write-only arguments** so it never lands in state. Marking it `sensitive` only hides it from CLI output; the state backend is encrypted to protect it at rest.

---

## Production notes

- **Dev vs prod differences** are entirely in the tfvars + a few module inputs: dev uses one NAT gateway, smaller instances, public EKS endpoint, no deletion protection; prod uses one NAT per AZ, `m5.large`/`db.r6g.large`, Multi-AZ RDS, private EKS endpoint, deletion protection, and a final snapshot.
- **Registry alternative:** the hand-written `vpc` and `eks` modules here are intentionally explicit for learning. In production you might instead use the verified `terraform-aws-modules/vpc/aws` and `terraform-aws-modules/eks/aws` registry modules (version-pinned) — the same composition pattern, less code to maintain.
- **CI:** run `fmt -check`, `validate`, and `plan` on every pull request; `apply` on merge to the environment branch.
