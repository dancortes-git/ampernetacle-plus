variable "name" {
  description = "Base name used for OCI resources created by the root stack."
  type        = string
  default     = "k8s-on-arm-in-oci"
}

variable "description" {
  description = "Description assigned to the OCI compartment created for the cluster."
  type        = string
  default     = "Kubernetes cluster running on ARM instances within Oracle Cloud Infrastructure, used to host containerized workloads."
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
  description = "OCI compute shape used for all cluster nodes."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "operating_system" {
  description = "Operating system name used to select the node image."
  type        = string
  default     = "Canonical Ubuntu"
}

variable "operating_system_version" {
  description = "Operating system version used to select the node image."
  type        = string
  default     = "22.04"
}

variable "operating_system_username" {
  description = "Default SSH username for the selected operating system image."
  type        = string
  default     = "ubuntu"
}

variable "how_many_nodes" {
  description = "Number of compute instances to create for the Kubernetes cluster."
  type        = number
  default     = 4
}

variable "availability_domain" {
  description = "Zero-based index of the OCI availability domain where nodes are created."
  type        = number
  default     = 0
}

variable "ocpus_per_node" {
  description = "Number of OCPUs allocated to each flexible-shape node."
  type        = number
  default     = 1
}

variable "memory_in_gbs_per_node" {
  description = "Memory in GiB allocated to each flexible-shape node."
  type        = number
  default     = 6
}

variable "http_backend_port" {
  description = "NodePort used by ingress-nginx for HTTP traffic and consumed by the NLB stack."
  type        = number
  default     = 30800
}

variable "https_backend_port" {
  description = "NodePort used by ingress-nginx for HTTPS traffic and consumed by the NLB stack."
  type        = number
  default     = 31800
}

variable "email_cert_issuer" {
  description = "Email address registered with Let's Encrypt for cert-manager certificate issuance."
  type        = string
}
