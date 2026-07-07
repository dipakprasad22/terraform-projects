variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to reach Postgres (e.g. the VPC CIDR)"
  type        = list(string)
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max autoscaled storage (GB)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Master password (source from Secrets Manager / ephemeral in real use)"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ (HA) — true for prod"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on delete (true for dev, false for prod)"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable RDS deletion protection (true for prod)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
