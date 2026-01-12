data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"
  name    = "${var.project}-${var.env}-vpc"
  cidr    = var.cidr
  azs     = slice(data.aws_availability_zones.available.names, 0, 3)


  # Subnetting: /24 subnets within /16 VPC (cleaner separation)
  public_subnets   = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_subnets  = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, i + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}


