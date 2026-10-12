terraform {
  required_version = ">= 1.10" # S3-native state locking (use_lockfile)

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The state bucket is created once by hand (versioned, encrypted, private).
  # Its name is not committed: terraform init -backend-config="bucket=<state bucket>"
  backend "s3" {
    key          = "aws-dev/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-dev"
      ManagedBy = "terraform"
    }
  }
}
