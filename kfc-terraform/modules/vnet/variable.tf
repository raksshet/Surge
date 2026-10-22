
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project" {
  type    = string
  default = "kfc"
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "region_code" {
  type    = string
  default = "ci"
}

variable "storage_unique_suffix" {
  description = "Six-character unique storage suffix"
  type        = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_address_prefixes" {
  type = list(string)
}
