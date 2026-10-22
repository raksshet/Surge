
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "unique_suffix" {
  description = "Lowercase alphanumeric suffix for global uniqueness"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{6}$", var.unique_suffix))
    error_message = "unique_suffix must contain exactly six lowercase letters or digits."
  }
}
