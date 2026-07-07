region             = "ap-south-1"
vpc_cidr           = "10.20.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
node_instance_type = "m5.large"
db_instance_class  = "db.r6g.large"
# db_password via: export TF_VAR_db_password=...
