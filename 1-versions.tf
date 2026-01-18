terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }

  backend "s3" {
    bucket  = "armageddon-tiqs-state-files"
    key     = "armageddon/class7/theo-labs/lab-1c-bonus-a.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}