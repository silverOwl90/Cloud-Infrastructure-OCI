variable "compartment_ocid" {
  type = string
}

variable "prefix" {
  description = "Prefix used to name the resources"
  type        = string
}

variable "vcn_cidr" {
  description = "VCN CIDR range"
  type        = string
}

variable "api_subnet_cidr" {
  description = "PUBLIC subnet for the Kubernetes API endpoint"
  type        = string
}

variable "lb_subnet_cidr" {
  description = "PUBLIC subnet for the Load Balancers created by Kubernetes"
  type        = string
}

variable "workers_subnet_cidr" {
  description = "PRIVATE subnet for the worker nodes"
  type        = string
}

variable "api_allowed_cidr" {
  description = "CIDR allowed to reach the Kubernetes API (recommended: your IP/32)"
  type        = string
}
