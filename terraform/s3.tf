/*
terraform {
  required_version = ">= 1.3.0"
  backend "s3" {
    region  = "<your_region>"
    profile = "default"
    key     = "terraform.tfstate"
    bucket  = "<your_bucket_name>"
    encrypt = true
  }
}
*/