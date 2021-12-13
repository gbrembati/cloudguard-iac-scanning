variable region {
  default = "us-east-1"
}
variable aws-access-key {
    description = "AWS Access Key"
    type = string
    sensitive = true
}
variable aws-secret-key {
    description = "AWS Secret Key"
    type = string
    sensitive = true
}