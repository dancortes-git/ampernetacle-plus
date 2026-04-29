# n8n Stack

The `/n8n` stack installs n8n on the Kubernetes cluster using the community n8n
Helm chart. It connects n8n to the external PostgreSQL database prepared by
`/postgresql/n8n_db`, configures ingress and TLS, enables persistent storage,
and creates a separate Python task runner deployment.

This stack is intended for experiments, demos, and learning. It is not a
production-hardened n8n deployment.

## 🧭 What it creates

- n8n Helm release, using the community Helm chart
- Ingress configured for the public `n8n_host`
- TLS through cert-manager and the `letsencrypt-prod` ClusterIssuer by default
- Persistent storage using the `nfs-dynamic` StorageClass by default
- Kubernetes Secret for runner authentication
- Python task runner ServiceAccount, Service, and Deployment

## ✅ Prerequisites

Before applying this stack:

1. Run the root apply script and wait for the cluster bootstrap to finish. The
   root script executes `/nlb` automatically.
2. Apply `/postgresql`.
3. Apply `/postgresql/n8n_db`.
4. Apply `/email` to provision OCI Email Delivery resources and generate SMTP
   credentials.
5. For public HTTPS access, point your n8n DNS host to the public load balancer
   IP created by the root apply script before requesting TLS certificates.
6. Create `terraform.tfvars` from the template and set `n8n_host`.
6. Authenticate with the OCI CLI using the `DEFAULT` profile:

   ```bash
   oci session authenticate
   ```

Create the required variables file:

Linux/macOS:

```bash
cp n8n/terraform.tfvars.template n8n/terraform.tfvars
```

Windows PowerShell:

```powershell
Copy-Item .\n8n\terraform.tfvars.template .\n8n\terraform.tfvars
```

Then edit `n8n/terraform.tfvars`:

```hcl
n8n_host = "n8n.example.com"
```

## 🚀 Create

Run from the repository root.

Linux/macOS:

```bash
./apply-n8n.sh
```

Windows PowerShell:

```powershell
.\ApplyN8n.ps1
```

After apply, access n8n through the hostname configured in `n8n_host`.

## 🛑 Destroy

Run from the repository root.

Linux/macOS:

```bash
./destroy-n8n.sh
```

Windows PowerShell:

```powershell
.\DestroyN8n.ps1
```

If you need to remove the n8n persistent volume claim after destroying the Helm
release, run:

```bash
kubectl delete pvc n8n-main-persistence -n n8n
```

## ⚙️ Configuration

Common variables are defined in `variables.tf`:

- `n8n_host`: required public DNS host for n8n
- `chart_version`: n8n Helm chart version
- `persistence_size`: persistent volume size, defaulting to `5Gi`
- `storage_class_name`: StorageClass used for persistence, defaulting to `nfs-dynamic`
- `ingress_class_name`: IngressClass name, defaulting to `nginx`
- `cert_manager_cluster_issuer`: cert-manager ClusterIssuer, defaulting to `letsencrypt-prod`
- `n8n_protocol`: public URL protocol, defaulting to `https`
- `email_key`: OCI Object Storage key for the email delivery Terraform state,
  defaulting to `email/terraform.tfstate`

The scripts provide backend and remote-state variables automatically from the
repository root, `/postgresql/n8n_db`, and `/email`.

## ⚠️ Notes

- DNS must point to the public load balancer IP before cert-manager can
  complete HTTP-01 certificate validation.
- The stack expects database outputs from `/postgresql/n8n_db`.
- The stack expects SMTP outputs from `/email`. Ensure the OCI Email Delivery
  sender domain is DNS-verified before testing email sending in n8n.
- Persistent data can outlive the Helm release through the PVC.
