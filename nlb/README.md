# OCI Network Load Balancer Stack

The `/nlb` stack creates an OCI Network Load Balancer for the Kubernetes
cluster created by the root stack. It forwards public HTTP and HTTPS traffic to
the ingress-nginx NodePorts running on every Kubernetes node.

> Important: this stack is already executed by the root `apply.sh` and
> `Apply.ps1` scripts. You do not need to run it after the root apply flow.
> Run it manually only if you intentionally want to maintain, test, or repair
> the NLB stack by itself.

This stack is intentionally small: it only owns the public Network Load
Balancer, backend sets, node backends, listeners, health checks, and the
`nlb_public_ip` output.

## 🧭 What it creates

- An OCI Network Load Balancer named `k8s-nlb`
- TCP listeners on ports `80` and `443`
- Backend sets for HTTP and HTTPS
- One backend per Kubernetes node, using node IPs from the root remote state
- TCP health checks against the ingress-nginx NodePorts

## ✅ Prerequisites

Before applying this stack:

1. Apply the root stack from the repository root.
2. Confirm the root stack generated the remote-state values consumed here:
   `compartment_id`, `subnet_id`, `k8s_node_ips`, `http_backend_port`, and
   `https_backend_port`.
3. Make sure `backend.hcl` exists in the repository root and points to the OCI
   Object Storage bucket used for Terraform state.
4. Authenticate with the OCI CLI using the `DEFAULT` profile:

   ```bash
   oci session authenticate
   ```

The root `apply.sh` and `Apply.ps1` scripts already apply this stack after the
core cluster. Treat manual execution as an advanced maintenance workflow, not
as part of the normal installation.

## 🚀 Create

Normal installation from the repository root:

Linux/macOS:

```bash
./apply.sh
```

Windows PowerShell:

```powershell
.\Apply.ps1
```

Manual apply is optional and only useful when you are working on this stack
directly. Export the remote-state variables first, then run Terraform from this
directory:

```bash
cd nlb
terraform init -backend-config=bucket=<bucket> -backend-config=namespace=<namespace>
terraform apply -parallelism=1
```

Use `-parallelism=1` if OCI reports temporary NLB state transition conflicts.

## 🛑 Destroy

Recommended from the repository root:

Linux/macOS:

```bash
./destroy.sh
```

Windows PowerShell:

```powershell
.\Destroy.ps1
```

The root destroy scripts destroy `/nlb` before destroying the root cluster
stack. If running manually, destroy this stack before the root stack:

```bash
cd nlb
terraform destroy -parallelism=1
```

## ⚠️ Notes

- This is not a Kubernetes `Service` of type `LoadBalancer`; it is an OCI NLB
  managed by Terraform.
- The cluster does not install the OCI cloud controller manager, so Kubernetes
  `LoadBalancer` services will still remain pending.
- Public traffic reaches applications through ingress-nginx and the NLB
  listeners on ports `80` and `443`.
