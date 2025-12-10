# Common module - provides shared resources and configurations

resource "null_resource" "common" {
  triggers = {
    env      = var.env
    app_name = var.app_name
    region   = var.aws_region
  }
}

