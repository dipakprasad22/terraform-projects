output "endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group ID of the RDS instance"
  value       = aws_security_group.this.id
}
