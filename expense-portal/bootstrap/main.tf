# Bootstrap: creates the S3 bucket used as the remote state backend for all
# environments. Run this ONCE, first, with local state — then the environments
# use the bucket it creates. (Chicken-and-egg: the state backend can't store its
# own creation in itself, so bootstrap uses local state.)

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # protect the state bucket from accidental destruction (T4)
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Purpose   = "terraform-remote-state"
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled" # keep state history — survivable loss (T2)
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms" # encrypt state at rest (secrets live in state, T2)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
