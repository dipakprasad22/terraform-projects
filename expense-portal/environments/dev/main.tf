# Dev environment root module: thin — it just calls the shared modules with
# dev-appropriate values and holds its own remote state. (T5 structure.)

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # remote state in the bootstrap-created S3 bucket, with native S3 locking (T2)
  backend "s3" {
    bucket       = "REPLACE-with-your-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region
}

locals {
  environment = "dev"
  name        = "expense-portal-dev"
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
  single_nat_gateway = true # cheaper for dev
  tags               = local.common_tags
}

module "ecr" {
  source           = "../../modules/ecr"
  repository_names = var.ecr_repositories
  force_delete     = true # convenient in dev
  tags             = local.common_tags
}

module "eks" {
  source                 = "../../modules/eks"
  cluster_name           = "${local.name}-eks"
  kubernetes_version     = var.kubernetes_version
  subnet_ids             = module.vpc.private_subnet_ids # consume VPC output
  node_instance_type     = var.node_instance_type
  node_desired_size      = 2
  node_min_size          = 1
  node_max_size          = 3
  endpoint_public_access = true
  tags                   = local.common_tags
}

module "rds" {
  source              = "../../modules/rds"
  identifier          = "${local.name}-db"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = [module.vpc.vpc_cidr] # only from within the VPC
  instance_class      = var.db_instance_class
  db_name             = "expenseportal"
  db_password         = var.db_password # supply via TF_VAR_db_password, not committed
  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false
  tags                = local.common_tags
}
