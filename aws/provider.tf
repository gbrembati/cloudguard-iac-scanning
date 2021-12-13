terraform {
    required_version = ">= 1.1.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 3.30.0"
        }
    }
}

# Configure the AWS Provider
provider "aws" {
  region     = var.region
  access_key = var.aws-access-key
  secret_key = var.aws-secret-key
}