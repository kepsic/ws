terraform {
  backend "s3" {
    bucket         = "emonstack-terraformbackend"
    key            = "terraform"
    region         = "eu-north-1"
    dynamodb_table = "terraform-emonstack-lock"
  }
}
