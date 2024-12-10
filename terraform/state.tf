terraform {
  backend "s3" {
    bucket = "datadrivers-demo-terraform-state"
    region = "eu-west-3"
  }
}

