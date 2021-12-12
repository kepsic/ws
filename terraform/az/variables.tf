#declare variables
variable "admin_user" {
  default     = "az-user"
  type        = string
  description = "Admin username for vm"
}

variable "resource_group_name" {
  type    = string
  default = "EMON"
}

variable "site_installer_file" {
  default     = "ansible_site_installer.sh"
  type        = string
  description = "Site installer filename"
}

variable "vm_name" {
  default     = "monitoring"
  type        = string
  description = "VM Name"
}

# azure region
variable "az_location" {
  type        = string
  description = "Azure region where the resources will be created"
  default     = "northeurope"
}


variable "image_offer" {
  type        = string
  description = "Image offer"
  default     = "0001-com-ubuntu-server-focal"
}
variable "image_sku" {
  type        = string
  description = "Image sku"
  default     = "20_04-lts"
}

variable "image_publisher" {
  type        = string
  description = "Image publisher"
  default     = "Canonical"
}

variable "image_version" {
  type        = string
  description = "Image version"
  default     = "20.04.202110260"
}
