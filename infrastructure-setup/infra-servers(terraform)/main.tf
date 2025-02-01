provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env_prefix}-vpc"
  }

}


module "subnet" {
  source = "./modules/subnet"

  env_prefix          = var.env_prefix
  availability_zone_1 = var.availability_zone_1
  subnet_cidr_block   = var.subnet_cidr_block
  vpc_id              = aws_vpc.dev-vpc.id
  availability_zone_2 = var.availability_zone_2
  availability_zone_3 = var.availability_zone_3
  availability_zone_4 = var.availability_zone_4
  availability_zone_5 = var.availability_zone_5

}


module "webserver" {
  source              = "./modules/webserver"
  vpc_id              = aws_vpc.dev-vpc.id
  my_ip               = var.my_ip
  env_prefix          = var.env_prefix
  ami_name            = var.ami_name
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
  availability_zone_1 = var.availability_zone_1
  subnet_id           = module.subnet.subnet_id.id
  vpc_cidr_block      = var.vpc_cidr_block
}
