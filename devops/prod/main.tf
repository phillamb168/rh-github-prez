terraform {
  backend "s3" {
    bucket  = "rh-github-prez-tfstate"
    key     = "./terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "rhgithubprez"
  }
}
