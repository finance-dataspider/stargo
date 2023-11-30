provider "aws" {
  region = "eu-central-1"  # Change this to your desired AWS region
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "stargo-ariel-t"

  versioning {
    enabled = true
  }

  force_destroy = true  # To enable bucket deletion with objects inside (use with caution)

  tags = {
    Terraform   = "true",
    Environment = "production",
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform_state_lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

terraform {
  backend "s3" {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "terraform.tfstate"
    region         = "us-east-1" # Specify your desired AWS region
    encrypt        = true
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.name
  }
}


module "api_caller" {
  source = ".\\modules\\asignment_1_apiCaller"

  aws_region     = "eu-central-1"  # Set your desired AWS region
  aws_account_id = "267087166096"  # Set your AWS account ID 
}