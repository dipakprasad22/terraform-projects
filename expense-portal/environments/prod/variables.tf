variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}
variable "node_instance_type" {
  type    = string
  default = "m5.large"
}
variable "db_instance_class" {
  type    = string
  default = "db.r6g.large"
}
variable "ecr_repositories" {
  type    = list(string)
  default = ["shopkart", "finledger", "panelpulse", "ratingsboard"]
}
variable "db_password" {
  type      = string
  sensitive = true
}
