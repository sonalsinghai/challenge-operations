# Bootstrap uses local backend initially
# After bootstrap, switch to S3 backend

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
