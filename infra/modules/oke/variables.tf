variable "tenancy_ocid" {
  description = "OCI tenancy OCID (used to list the Availability Domains)"
  type        = string
  sensitive   = true
}

variable "compartment_ocid" {
  type = string
}

variable "prefix" {
  description = "Prefix used to name the resources"
  type        = string
}

# ---------- Network (outputs of the network module) ----------
variable "vcn_id" {
  type = string
}

variable "api_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "workers_subnet_id" {
  type = string
}

# ---------- Cluster / nodes ----------
variable "kubernetes_version" {
  description = "Kubernetes version (e.g. v1.31.1). If null, the latest available version is used."
  type        = string
  default     = null
}

variable "node_shape" {
  description = "Node shape. Use VM.Standard.A1.Flex for the Always Free tier (ARM)."
  type        = string
}

variable "node_ocpus" {
  type = number
}

variable "node_memory_gbs" {
  type = number
}

variable "node_count" {
  type = number
}

variable "node_boot_volume_gbs" {
  type = number
}

variable "ssh_public_key" {
  description = "Optional SSH public key for the nodes"
  type        = string
  default     = null
}
