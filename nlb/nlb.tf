resource "oci_network_load_balancer_network_load_balancer" "k8s_nlb" {
  depends_on = [oci_core_instance._]

  display_name   = "k8s-nlb"
  compartment_id = data.terraform_remote_state.k8s.outputs.compartment_id
  subnet_id      = data.terraform_remote_state.k8s.outputs.subnet_id

  is_private                     = false
  is_preserve_source_destination = false
}

resource "oci_network_load_balancer_backend_set" "http_backend" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  name                     = "http-backend"
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol = "TCP"
    port     = data.terraform_remote_state.k8s.outputs.http_backend_port
  }
}

resource "oci_network_load_balancer_backend_set" "https_backend" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  name                     = "https-backend"
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol = "TCP"
    port     = data.terraform_remote_state.k8s.outputs.https_backend_port
  }
}

resource "oci_network_load_balancer_backend" "http_nodes" {
  for_each = toset(data.terraform_remote_state.k8s.outputs.k8s_node_ips)

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.http_backend.name

  ip_address = each.value
  port       = data.terraform_remote_state.k8s.outputs.http_backend_port
}

resource "oci_network_load_balancer_backend" "https_nodes" {
  for_each = toset(data.terraform_remote_state.k8s.outputs.k8s_node_ips)

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.https_backend.name

  ip_address = each.value
  port       = data.terraform_remote_state.k8s.outputs.https_backend_port
}

resource "oci_network_load_balancer_listener" "http_listener" {
  depends_on = [
    oci_network_load_balancer_backend_set.http_backend
  ]
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  name                     = "http"
  default_backend_set_name = oci_network_load_balancer_backend_set.http_backend.name
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_listener" "https_listener" {
  depends_on = [
    oci_network_load_balancer_listener.http_listener,
    oci_network_load_balancer_backend_set.https_backend
  ]
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.k8s_nlb.id
  name                     = "https"
  default_backend_set_name = oci_network_load_balancer_backend_set.https_backend.name
  port                     = 443
  protocol                 = "TCP"
}

output "nlb_public_ip" {
  value = oci_network_load_balancer_network_load_balancer.k8s_nlb.ip_addresses[0].ip_address
}