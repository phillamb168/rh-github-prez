terragrunt = {
  terraform {
    source = "../../terraform-modules//redis"
  }

  dependencies {
    paths = ["../vpc"]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
