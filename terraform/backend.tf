terraform {
  backend "s3" {
    bucket  = "ce-capstone-tf-state-070638634202"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
