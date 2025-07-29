# Backend Configuration
# State storage configuration

terraform {
  # Local backend for development
  backend "local" {
    path = "terraform.tfstate"
  }
}