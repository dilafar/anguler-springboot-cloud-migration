terraform {
  backend "s3" {
    bucket = "terraform-eks-state-data-test"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }

  }

  required_version = ">= 1.0"

}