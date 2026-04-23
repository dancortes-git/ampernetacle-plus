variable "name" {
  type    = string
  default = "k8s-on-arm-in-oci"
}

variable "description" {
  type    = string
  default = "Kubernetes cluster running on ARM instances within Oracle Cloud Infrastructure, used to host containerized workloads."
}

/*
Available flex shapes:
"VM.Optimized3.Flex"  # Intel Ice Lake
"VM.Standard3.Flex"   # Intel Ice Lake
"VM.Standard.A1.Flex" # Ampere Altra
"VM.Standard.E3.Flex" # AMD Rome
"VM.Standard.E4.Flex" # AMD Milan
*/

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "operating_system" {
  type    = string
  default = "Canonical Ubuntu"
}

variable "operating_system_version" {
  type    = string
  default = "22.04"
}

variable "operating_system_username" {
  type    = string
  default = "ubuntu"
}

variable "how_many_nodes" {
  type    = number
  default = 4
}

variable "availability_domain" {
  type    = number
  default = 0
}

variable "ocpus_per_node" {
  type    = number
  default = 1
}

variable "memory_in_gbs_per_node" {
  type    = number
  default = 6
}

variable "http_backend_port" {
  type    = number
  default = 30800
}

variable "https_backend_port" {
  type    = number
  default = 31800
}

variable "email_cert_issuer" {
  type    = string
  default = "daniel@dancortes.com"
}