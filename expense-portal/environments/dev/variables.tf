variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}
variable "kubernetes_version" {
  type    = string
  default = "1.30"
}
variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "ecr_repositories" {
  type    = list(string)
  default = ["shopkart", "finledger", "panelpulse", "ratingsboard"]
}
variable "db_password" {
  type      = string
  sensitive = true
}
