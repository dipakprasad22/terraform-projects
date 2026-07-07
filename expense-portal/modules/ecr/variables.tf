variable "repository_names" {
  description = "List of ECR repository names to create (one per service)"
  type        = list(string)
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE tags"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "Allow deleting repositories that still contain images (true for dev)"
  type        = bool
  default     = false
}

variable "untagged_expiry_days" {
  description = "Days after which untagged images are expired"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
