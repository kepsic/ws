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

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-emonstack-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}