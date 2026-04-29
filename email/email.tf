resource "oci_email_sender" "_" {
  compartment_id = data.terraform_remote_state.root.outputs.compartment_id
  email_address  = var.smtp_sender_email
}

resource "oci_identity_smtp_credential" "_" {
  user_id     = var.smtp_user_id
  description = "SMTP credential for n8n email delivery"
}
