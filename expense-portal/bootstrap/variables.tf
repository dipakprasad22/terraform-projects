variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Globally-unique name for the Terraform state bucket"
  type        = string

  validation {
    condition     = length(var.state_bucket_name) >= 3 && length(var.state_bucket_name) <= 63
    error_message = "S3 bucket names must be between 3 and 63 characters."
  }
}
