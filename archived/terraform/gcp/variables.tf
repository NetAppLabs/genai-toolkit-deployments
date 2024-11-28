variable "project" {
  description = "The GCP project to use"
  type        = string
}

variable "region" {
  description = "The region where the resources will be created"
  type        = string
}

variable "zone" {
  description = "The zone where the resources will be created"
  type        = string
}

variable "network" {
  description = "The network to use for the instance"
  type        = string 
}

variable "subnetwork" {
  description = "The subnetwork to use for the instance"
  type        = string
}

variable "source_ip_ranges" {
  description = "A list of CIDRs that can access to the toolkit"
  type        = list(string)
}

variable "gcnv_volumes" {
  description = "List of GCNV NFS servers to mount"
  type        = list(string)
}

variable "ontap_volumes" {
  description = "List of ONTAP NFS servers to mount"
  type        = list(string)
}
