terragrunt = {
  terraform {
    source = "../../terraform-modules//webserver"
  }

  dependencies {
    paths = ["../vpc", "../database", "../redis"]
  }

  include = {
    path = "${find_in_parent_folders()}"
  }
}

# overwrite default and use bigger instances in prod
instance_type = "t3.small"
