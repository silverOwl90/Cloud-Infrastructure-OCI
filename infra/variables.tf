variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to OCI private key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OCI region"
  type        = string
}

variable "compartment_ocid" {
  type = string
}

variable "prefix" {
  description = "Prefix used to name the resources"
  type        = string
  default     = "demo"
}

variable "vcn_cidr" {
  description = "VCN CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "api_subnet_cidr" {
  description = "PUBLIC subnet for the Kubernetes API endpoint"
  type        = string
  default     = "10.0.0.0/28"
}

variable "lb_subnet_cidr" {
  description = "PUBLIC subnet for the Load Balancers created by Kubernetes"
  type        = string
  default     = "10.0.20.0/24"
}

variable "workers_subnet_cidr" {
  description = "PRIVATE subnet for the worker nodes"
  type        = string
  default     = "10.0.10.0/24"
}

variable "api_allowed_cidr" {
  description = "CIDR allowed to reach the Kubernetes API (recommended: your IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "kubernetes_version" {
  description = "Kubernetes version (e.g. v1.31.1). If null, the latest available version is used."
  type        = string
  default     = null
}

variable "node_shape" {
  description = "Node shape. Use VM.Standard.A1.Flex for the Always Free tier (ARM)."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  type    = number
  default = 1
}

variable "node_memory_gbs" {
  type    = number
  default = 8
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_boot_volume_gbs" {
  type    = number
  default = 50
}

variable "ssh_public_key" {
  description = "Optional SSH public key for the nodes"
  type        = string
  default     = null
}

variable "namespace" {
  type    = string
  default = "demo"
}

variable "replicas" {
  type    = number
  default = 2
}

variable "message" {
  description = "Message shown on the web page"
  type        = string
  default     = "¡Hola desde OKE desplegado con Terraform + Helm!"
}
