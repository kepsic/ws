variable "aws_access_key" {
  default     = "<access_key_not_set>"
  type        = string
  description = "access_key for AWS"

}
variable "aws_secret_key" {
  default     = "<secret_key_not_set>"
  type        = string
  description = "secret_key for AWS"
}

variable "aws_region" {
  default = "eu-north-1"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

resource "aws_s3_bucket" "bucket" {
  bucket = "emonstack-terraformbackend"
}