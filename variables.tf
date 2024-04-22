variable "availability_zones" {
  description = "Lista de zonas de disponibilidade"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ami_lnx_virg" {
  description = "Lista de zonas de disponibilidade"
  type        = string
  default     = "ami-0fe630eb857a6ec83"
}

variable "ami_win_orh" {
  description = "Lista de zonas de disponibilidade"
  type        = string
  default     = "ami-02db44a38cfb5d753"
}

variable "ami_win_virg" {
  description = "Lista de zonas de disponibilidade"
  type        = string
  default     = "ami-0d2a904b23cbe737a"
}

