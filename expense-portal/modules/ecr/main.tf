# ECR module: one repository per service (for_each, T4), each with image scanning
# on push and a lifecycle policy that expires old untagged images.

locals {
  common_tags = merge(var.tags, {
    Module    = "ecr"
    ManagedBy = "terraform"
  })
}

resource "aws_ecr_repository" "this" {
  for_each             = toset(var.repository_names)
  name                 = each.key
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, { Name = each.key })
}

# expire untagged images after N days to control storage cost
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images older than ${var.untagged_expiry_days} days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = var.untagged_expiry_days
      }
      action = { type = "expire" }
    }]
  })
}
