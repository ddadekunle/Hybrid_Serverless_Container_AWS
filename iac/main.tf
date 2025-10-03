locals {
  tags = {
    Project   = var.project
    ManagedBy = "Terraform"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.8"

  name = "${var.project}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = local.tags

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 2

      instance_types = ["t3.large"]
      labels         = { role = "general" }
    }

  }
  tags = local.tags
}

resource "aws_ecr_repository" "api" {
  name                 = "${var.project}-api"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.tags
}

resource "aws_s3_bucket" "payloads" {
  bucket = var.payload_bucket
  tags = local.tags
  }

resource "aws_s3_bucket_versioning" "payloads" {
  bucket = aws_s3_bucket.payloads.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "payloads" {
  bucket = aws_s3_bucket.payloads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "jobs" {
  name         = var.job_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jobId"
  attribute {
    name = "jobId"
    type = "S"
  }
  tags = local.tags
}

resource "aws_kms_key" "general" {
  description             = "KMS key for ${var.project}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags = local.tags
}


output "cluster_name"           { value = module.eks.cluster_name}
output "cluster_endpoint"       { value = module.eks.cluster_endpoint}
output "cluster_ca"             { value = module.eks.cluster_certificate_authority_data} 
output "payload_bucket_name"   { value = aws_s3_bucket.payloads.bucket}
output "job_table_name"        { value = aws_dynamodb_table.jobs.name}
output "ecr_repo"               { value = aws_ecr_repository.api.repository_url}
  
