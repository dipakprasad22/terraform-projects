# RDS module: a PostgreSQL instance in private subnets, with a subnet group and
# a security group. Protected with prevent_destroy (T4). The password is passed
# in as a sensitive variable (in real use, source it from Secrets Manager / an
# ephemeral value rather than committing it — see README).

locals {
  common_tags = merge(var.tags, {
    Module    = "rds"
    ManagedBy = "terraform"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = merge(local.common_tags, { Name = "${var.identifier}-subnet-group" })
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Allow Postgres from within the VPC"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.identifier}-sg" })

  # ingress rules generated from a variable via a dynamic block (T6)
  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      description = "Postgres from ${ingress.value}"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password # sensitive; see README for secret handling

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  backup_retention_period = var.backup_retention_period

  tags = local.common_tags

  lifecycle {
    # guardrail: never let Terraform destroy the production database (T4)
    prevent_destroy = true
  }
}
