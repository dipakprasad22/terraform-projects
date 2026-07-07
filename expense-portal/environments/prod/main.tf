# Prod environment root module: same modules as dev, production-grade values —
# multi-AZ, one NAT per AZ, larger instances, deletion protection. Separate
# state + backend from dev = isolation and limited blast radius (T2/T6).

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "REPLACE-with-your-state-bucket"
    key          = "prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

locals {
  environment = "prod"
  name        = "expense-portal-prod"
  common_tags = {
    Project     = "expense-portal"
    Environment = local.environment
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = false # one NAT per AZ for HA
  tags               = local.common_tags
}

module "ecr" {
  source           = "../../modules/ecr"
  repository_names = var.ecr_repositories
  force_delete     = false # protect prod images
  tags             = local.common_tags
}

module "eks" {
  source                 = "../../modules/eks"
  cluster_name           = "${local.name}-eks"
  kubernetes_version     = var.kubernetes_version
  subnet_ids             = module.vpc.private_subnet_ids
  node_instance_type     = var.node_instance_type
  node_desired_size      = 3
  node_min_size          = 3
  node_max_size          = 10
  endpoint_public_access = false # private endpoint in prod
  tags                   = local.common_tags
}

module "rds" {
  source              = "../../modules/rds"
  identifier          = "${local.name}-db"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [module.vpc.vpc_cidr]
  instance_class      = var.db_instance_class
  db_name             = "expenseportal"
  db_password         = var.db_password
  multi_az            = true  # HA in prod
  skip_final_snapshot = false # keep a final snapshot in prod
  deletion_protection = true  # protect prod DB
  tags                = local.common_tags
}
