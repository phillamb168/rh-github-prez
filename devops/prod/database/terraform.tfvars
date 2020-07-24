terragrunt = {
  terraform {
    source = "../../terraform-modules//database"
  }

  dependencies {
    paths = ["../vpc"]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
