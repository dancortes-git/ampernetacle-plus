locals {
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
}

resource "null_resource" "fix_ssh_key_permissions_windows" {
  count = local.is_windows ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
    icacls "${local_file.ssh_private_key.filename}" /inheritance:r
    icacls "${local_file.ssh_private_key.filename}" /grant:r "$($env:USERNAME):(F)"
    EOT

    interpreter = ["pwsh", "-Command"]
  }
}

resource "null_resource" "fetch_kubeconfig_windows" {
  depends_on = [oci_core_instance._[1]]
  count      = local.is_windows ? 1 : 0

  provisioner "local-exec" {
    command = "pwsh -ExecutionPolicy Bypass -File Fetch-KubeConfig.ps1 -KubeHost ${oci_core_instance._[1].public_ip} -KubeUser k8s -SshPrivateKeyFileName ${local_file.ssh_private_key.filename}"
  }
}

resource "null_resource" "fetch_kubeconfig_unix" {
  depends_on = [oci_core_instance._[1]]
  count      = local.is_windows ? 0 : 1

  provisioner "local-exec" {
    command = "bash fetch-kubeconfig.sh ${oci_core_instance._[1].public_ip} k8s ${local_file.ssh_private_key.filename}"
  }
}
