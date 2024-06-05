variable "location" {
  type        = string
  description = "The location/region where the virtual network is created."
  default     = "uksouth"
}

variable "name" {
  type        = string
  description = "Used in naming of resources."
  default     = "powerpipe"
}