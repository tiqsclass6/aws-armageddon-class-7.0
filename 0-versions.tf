terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket  = "armageddon-tiqs-state-files"
    key     = "armageddon/class7/theo-labs/lab-3a.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}