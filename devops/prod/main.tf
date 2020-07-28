terraform {
  backend "s3" {
    bucket = "rh-github-prez-tfstate"
    key = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    profile = "rhgithubprez"
  }
}
