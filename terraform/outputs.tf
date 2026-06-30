output "autoinstall_output_dir" {
  value = local.autoinstall_output_dir
}

output "nodes_json_path" {
  value = local.nodes_json_path
}

output "vm_names" {
  value = [for node in var.nodes : node.name]
}

