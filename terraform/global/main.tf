module "ecr" {
  source = "../modules/ecr"

  repositories = {
    api-golang = {
      name = "${var.project}/api-golang"
    }
    api-node = {
      name = "${var.project}/api-node"
    }
    load-generator-python = {
      name = "${var.project}/load-generator-python"
    }
    client-react = {
      name = "${var.project}/client-react"
    }
    api-golang-migrator = {
      name = "${var.project}/api-golang-migrator"
    }
  }

  force_delete   = true
  images_to_keep = 5

  tags = {
    Project = var.project
  }
}
