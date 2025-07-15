/*
terraform {  
  backend "s3" {  
    bucket       = "<your_bucket_name>"
    key          = "terraform.tfstate"
    region       = "<your_region>"
    encrypt      = true  
    use_lockfile = true  #S3 native locking
  }  
}
*/

