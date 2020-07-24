terragrunt = {
  terraform {
    source = "../../terraform-modules//vpc"
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}
