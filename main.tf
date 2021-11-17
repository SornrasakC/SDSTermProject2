provider "aws" {
    region = var.region
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDVQIuNAVaPBwDc/qsJ1FHEoZ+mY+yoJMGVLia7kKBRsjqzNYXQtWStTyN55ADpGOmA6UM1eIKpNWEOMUGT1s8AuSMJKqiBVsaZKx9zyZZKaiqRX0gmmgn71bgq9YbT6mm/5AlKKisrp2SriyuFPti2FgVPziym+ont3nFQpxWWFMSMFfx/Iqa/ggoHdZyk6CIe03qE5EgoiryZGSKzPOt1YShEa/oa9tSauqhlA58bhijXPpP/JbOxUVOB5wGbP4zoOaSSw9SXumLXuzFos4kiMotQ/Zki7KdP86aLp/DgGdP/GruQzyvBGZL2xDS+0uizNA6JQqUJVP57Iq7eEDM/FzivYRrccu4NJ3oV96id/N3rzsYYgCSH3rZEl/C7RQI+ik39YLZKmKeMGyuY91AOQhCyM5tlv2nqWhinvAh4tIdcvb3y63xAif6NdB5whukB2rio79a6NC8xBcQP/P8iUM2csTNT8TxWBXFWUAl2gI6nc+HviczxvxInET2M8zs= user@Kaharu"
}

module "iam" {
  source = "./modules/iam"
}

module "network" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
  public_subnet_cidr = var.nextcloud_cidr
  private_inner_subnet_cidr = var.db_nextcloud_cidr
  private_outer_subnet_cidr = var.db_rt_cidr
  availability_zone = var.availability_zone

  instance_id = module.nextcloud-app.nextcloud_core_instance_id
}

module "s3" {
  source = "./modules/services/s3"

  s3_bucket_name = var.bucket_name
  nextcloud_iam_user_arn = module.iam.nextcloud_iam_user_arn
  terraform_iam_user_arn = module.iam.terraform_iam_user_arn

  force_destroy = var.force_datastore_destroy
}

module "maria" {
  source = "./modules/services/maria"
  availability_zone = var.availability_zone
  instance_type = var.nextcloud_instance_type
  aws_ami = var.ami

  vpc_id = module.network.vpc_id
  inner_subnet_id = module.network.private_inner_subnet_id
  outer_subnet_id = module.network.private_outer_subnet_id

  db_name = var.database_name
  db_user = var.database_user
  db_pass = var.database_pass
}

module "nextcloud-app" {
  source = "./modules/services/nextcloud-app"
  availability_zone = var.availability_zone
  instance_type = var.nextcloud_instance_type
  aws_ami = var.ami

  vpc_id = module.network.vpc_id
  inner_subnet_id = module.network.private_inner_subnet_id
  outer_subnet_id = module.network.public_subnet_id

  db_name = var.database_name
  db_user = var.database_user
  db_pass = var.database_pass
  db_endpoint = "10.0.2.51"

  admin_user = var.admin_user
  admin_pass = var.admin_pass
  # data_dir = var.

  aws_region = var.region
  s3_bucket_name = var.bucket_name
  s3_access_key = module.iam.nextcloud_iam_user_access_key
  s3_secret_key = module.iam.nextcloud_iam_user_secret_key

  dep = module.maria.nonce
}

# resource "aws_instance" "nextcloud_bast_instance"{
#     ami = var.ami
#     instance_type = var.instance_type
#     vpc_security_group_ids = [aws_security_group.nextcloud_bast_sg.id]
#     subnet_id = var.outer_subnet_id

#     key_name = "deployer-key"

#     tags = {
#         Name = "Nextcloud app"
#     }

#     user_data = "${data.template_cloudinit_config.cloudinit-nextcloud.rendered}"
# }
# resource "aws_security_group" "nextcloud_bast_sg" {
#     name = "nextcloud_bast_sg"
#     vpc_id = module.network.vpc_id

#     ingress {
#         from_port="80"
#         to_port="80"
#         protocol="tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     ingress {
#         from_port="22"
#         to_port="22"
#         protocol="tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port       = 0
#         to_port         = 0
#         protocol        = "-1"
#         cidr_blocks     = ["0.0.0.0/0"]
#     }


#     lifecycle {
#         create_before_destroy = true
#     }
# }