variable "namespace" {
  type = string
}

variable "replicas" {
  type = number
}

variable "message" {
  description = "Message shown on the web page"
  type        = string
}
