terraform {
  required_version = ">= 1.6.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  repo_root              = abspath("${path.module}/..")
  lab_config_path        = abspath("${path.module}/${var.lab_config_path}")
  autoinstall_output_dir = abspath("${path.module}/${var.autoinstall_output_dir}")
  nodes_json_path        = "${local.autoinstall_output_dir}/nodes.json"
}

resource "local_file" "nodes_json" {
  filename = local.nodes_json_path
  content = jsonencode({
    username            = var.admin_username
    full_name           = var.admin_full_name
    password_hash       = var.admin_password_hash
    ssh_authorized_keys = var.ssh_authorized_keys
    nodes               = var.nodes
  })
}

resource "null_resource" "autoinstall_media" {
  depends_on = [local_file.nodes_json]

  triggers = {
    nodes_json_sha1 = local_file.nodes_json.content_sha1
    script_sha1     = filesha1("${local.repo_root}/hyperv/powershell/New-LabAutoinstallMedia.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${local.repo_root}/hyperv/powershell/New-LabAutoinstallMedia.ps1' -NodesJsonPath '${local.nodes_json_path}' -OutputDirectory '${local.autoinstall_output_dir}'"
  }
}

resource "null_resource" "lab_network" {
  triggers = {
    config_sha1 = filesha1(local.lab_config_path)
    script_sha1 = filesha1("${local.repo_root}/hyperv/powershell/New-LabNetwork.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${local.repo_root}/hyperv/powershell/New-LabNetwork.ps1' -ConfigPath '${local.lab_config_path}'"
  }
}

resource "null_resource" "lab_vms" {
  depends_on = [
    null_resource.autoinstall_media,
    null_resource.lab_network
  ]

  triggers = {
    config_sha1 = filesha1(local.lab_config_path)
    script_sha1 = filesha1("${local.repo_root}/hyperv/powershell/New-LabVMs.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${local.repo_root}/hyperv/powershell/New-LabVMs.ps1' -ConfigPath '${local.lab_config_path}'"
  }
}

resource "null_resource" "attach_autoinstall_media" {
  depends_on = [null_resource.lab_vms]

  triggers = {
    nodes_json_sha1 = local_file.nodes_json.content_sha1
    script_sha1     = filesha1("${local.repo_root}/hyperv/powershell/Add-LabAutoinstallMedia.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${local.repo_root}/hyperv/powershell/Add-LabAutoinstallMedia.ps1' -NodesJsonPath '${local.nodes_json_path}' -MediaDirectory '${local.autoinstall_output_dir}'"
  }
}

resource "null_resource" "start_lab" {
  depends_on = [null_resource.attach_autoinstall_media]

  triggers = {
    config_sha1 = filesha1(local.lab_config_path)
    script_sha1 = filesha1("${local.repo_root}/hyperv/powershell/Start-Lab.ps1")
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${local.repo_root}/hyperv/powershell/Start-Lab.ps1' -ConfigPath '${local.lab_config_path}'"
  }
}

