
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project" {
  description = "Project abbreviation"
  type        = string
  default     = "kfc"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "region_code" {
  description = "Short region code"
  type        = string
  default     = "ci"
}

variable "unique_suffix" {
  description = "Globally unique alphanumeric suffix for storage"
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual network address range"
  type        = list(string)
}

variable "subnet_address_prefix" {
  description = "Subnet address range"
  type        = list(string)
}

variable "vm_size" {
  description = "Azure Linux VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Linux VM administrator username"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key" {
  description = "SSH public key for Linux VM login"
  type        = string
}

variable "admin_source_ip_cidr" {
  description = "Public IP CIDR allowed to connect over SSH"
  type        = string
}
