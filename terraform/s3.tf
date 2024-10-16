terraform {
  required_version = ">= 1.3.0"
  backend "s3" {
    region  = "<your_region>" ##US
    #region  = "<your_region>" ## EU
    profile = "default"
    key     = "terraform.tfstate"
    bucket  = "<your_bucket_name>" ##US
    #bucket = "<your_bucket_name>" ##EU
    encrypt = true
  }
}
