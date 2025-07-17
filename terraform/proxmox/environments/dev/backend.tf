# Backend Configuration
# Local backend for development environment

terraform {
  # Local backend for development
  backend "local" {
    path = "terraform.tfstate"
  }
}