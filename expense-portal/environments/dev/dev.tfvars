region             = "ap-south-1"
vpc_cidr           = "10.10.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
node_instance_type = "t3.medium"
db_instance_class  = "db.t3.micro"
# db_password is NOT set here — pass it via: export TF_VAR_db_password=...
