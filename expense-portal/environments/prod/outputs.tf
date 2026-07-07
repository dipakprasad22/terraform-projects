output "vpc_id" {
  value = module.vpc.vpc_id
}
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}
output "rds_endpoint" {
  value = module.rds.endpoint
}
