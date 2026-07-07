output "state_bucket" {
  description = "Name of the S3 state bucket (use in each environment's backend block)"
  value       = aws_s3_bucket.state.id
}
