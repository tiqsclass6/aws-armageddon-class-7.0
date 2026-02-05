provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "shinjuku"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "liberdade"
  region = "sa-east-1"
}