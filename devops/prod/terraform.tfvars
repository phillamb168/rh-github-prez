terragrunt = {
  remote_state {
    backend = "s3"

    config {
      bucket = "rh-github-prez-tfstate"
      key = "${path_relative_to_include()}/terraform.tfstate"
      region = "us-east-1"
      encrypt = true
      profile = "rhgithubprez"
    }
  }

  terraform {
    extra_arguments "custom_vars" {
      commands = [
        "apply",
        "plan",
        "import",
        "push",
        "refresh",
        "destroy"
      ]

      arguments = [
        "-var",
        "region=us-east-1",
        "-var",
        "environment=prod",
        "-var",
        "name=lamp",
        "-var",
        "tfstate_bucket=rh-github-prez-tfstate",
        "-var",
        "profile=rhgithubprez"
      ]
    }
  }
}
