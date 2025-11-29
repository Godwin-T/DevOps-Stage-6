terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "hng-13-terraform-state"
    key            = "devops-stage6/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hng-13-terraform-locks"
    encrypt        = true
  }
}
