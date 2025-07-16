# Local Values
# Computed values and common tags used across resources

locals {
  # Common tags for all resources
  common_tags = concat(
    var.common_tags,
    ["terraform", "dev"]
  )
}