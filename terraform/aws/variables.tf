#declare variables
variable "admin_user" {
  default     = "emon-user"
  type        = string
  description = "Admin username for vm"
}

variable "ssh_private_key" {
  default     = "not set"
  type        = string
  description = "SSH Private Key"
}

variable "ssh_public_key" {
  default     = "not set"
  type        = string
  description = "SSH Public Key"
}


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
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "subnet_one_cidr" {
  default = "10.0.1.0/24"
}
variable "subnet_two_cidr" {
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}
variable "route_table_cidr" {
  default = "0.0.0.0/0"
}
variable "web_ports" {
  default = ["22", "80", "443", "3306"]
}
variable "db_ports" {
  default = ["22", "3306"]
}
variable "images" {
  type = map(any)
  default = {
    "us-east-1"      = "ami-0937dcc711d38ef3f"
    "us-east-2"      = "ami-04328208f4f0cf1fe"
    "us-west-1"      = "ami-0799ad445b5727125"
    "us-west-2"      = "ami-032509850cf9ee54e"
    "ap-south-1"     = "ami-0937dcc711d38ef3f"
    "ap-northeast-2" = "ami-018a9a930060d38aa"
    "ap-southeast-1" = "ami-04677bdaa3c2b6e24"
    "ap-southeast-2" = "ami-0c9d48b5db609ad6e"
    "ap-northeast-1" = "ami-0d7ed3ddb85b521a6"
    "ca-central-1"   = "ami-0de8b8e4bc1f125fe"
    "eu-central-1"   = "ami-0eaec5838478eb0ba"
    "eu-west-1"      = "ami-0fad7378adf284ce0"
    "eu-west-2"      = "ami-0664a710233d7c148"
    "eu-west-3"      = "ami-0854d53ce963f69d8"
    "eu-north-1"     = "ami-092cce4a19b438926"
  }
}


variable "site_installer_file" {
  default     = "ansible_site_installer.sh"
  type        = string
  description = "Site installer filename"
}