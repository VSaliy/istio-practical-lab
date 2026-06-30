variable "lab_config_path" {
  description = "Path to the existing Hyper-V lab config, relative to the terraform directory."
  type        = string
  default     = "../hyperv/config/lab-config.psd1"
}

variable "autoinstall_output_dir" {
  description = "Directory for generated cloud-init/autoinstall files and seed ISOs, relative to the terraform directory."
  type        = string
  default     = "../build/autoinstall"
}

variable "admin_username" {
  description = "Ubuntu user created by autoinstall."
  type        = string
  default     = "vgs"
}

variable "admin_full_name" {
  description = "Full name for the Ubuntu autoinstall identity block."
  type        = string
  default     = "vgs"
}

variable "admin_password_hash" {
  description = "SHA-512 password hash for the Ubuntu user. Generate with: openssl passwd -6"
  type        = string
  sensitive   = true
}

variable "ssh_authorized_keys" {
  description = "SSH public keys to add to the autoinstall user."
  type        = list(string)
  default     = []
}

variable "nodes" {
  description = "Lab VM autoinstall definitions."
  type = list(object({
    name       = string
    hostname   = string
    address    = string
    prefix     = number
    gateway    = string
    nameservers = list(string)
  }))

  default = [
    {
      name        = "k8s-control-01"
      hostname    = "k8s-control-01"
      address     = "172.22.0.10"
      prefix      = 24
      gateway     = "172.22.0.1"
      nameservers = ["1.1.1.1", "8.8.8.8"]
    },
    {
      name        = "k8s-worker-01"
      hostname    = "k8s-worker-01"
      address     = "172.22.0.11"
      prefix      = 24
      gateway     = "172.22.0.1"
      nameservers = ["1.1.1.1", "8.8.8.8"]
    },
    {
      name        = "k8s-worker-02"
      hostname    = "k8s-worker-02"
      address     = "172.22.0.12"
      prefix      = 24
      gateway     = "172.22.0.1"
      nameservers = ["1.1.1.1", "8.8.8.8"]
    }
  ]
}

