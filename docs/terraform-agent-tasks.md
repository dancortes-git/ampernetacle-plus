# Terraform Agent Task Instructions for Ampernetacle Plus

## Main task types

1. Terraform code fixes
2. Project documentation improvements
3. Configuration and variable updates
4. `cloud-init` adjustments and `kubeconfig` generation
5. OCI Network Load Balancer updates
6. Kubernetes add-on updates through Helm
7. PostgreSQL, n8n database initialization, and n8n stack updates
8. PowerShell helper script maintenance

## General approach

- Read `AGENTS.md`, this file, `docs/terraform-agent-guidelines.md`, the README, and the relevant `.tf`, `.yaml`, `.tpl`, or `.ps1` files before suggesting changes.
- Do not change the cluster's core architecture without an explicit reason.
- Keep the default behavior: 4 nodes, `VM.Standard.A1.Flex`, Ubuntu 22.04.
- If performance or additional support is needed, add optional settings via variables rather than replacing defaults.
- Preserve the separate Terraform stacks and backend keys unless the user explicitly asks for a migration.
- Keep documentation in English.

## Stack selection

- Use the root stack for OCI compartment, VCN, subnet, compute nodes, cloud-init, SSH keys, kubeconfig, and core outputs.
- Use `/nlb` for public HTTP/HTTPS forwarding to ingress-nginx NodePorts.
- Use `/postgresql` for cluster-wide PostgreSQL installation.
- Use `/postgresql/n8n_db` for creating the n8n database, database user, and application Secrets.
- Use `/n8n` for the n8n Helm release, ingress, persistence, and task runner resources.
- When a change crosses stacks, update the producer output first, then the consumer remote-state reference.

## How to fix bugs

- Identify the correct Terraform file for the change.
- Verify that the change does not break other dependencies.
- Ensure formatting is consistent with `terraform fmt`.
- Add a brief comment only if it is needed to explain non-obvious behavior.
- If a bug involves remote state, inspect both the producing stack's `outputs.tf` and the consuming stack's `state.tf` or locals.
- If a bug involves Kubernetes resources, check namespace, Secret name, Helm values, and provider `config_path` assumptions.

## How to handle new improvements

- For new variables, document them in `README.md` and `variables.tf`.
- For new OCI resources, confirm the object fits the current provisioning flow and has a clear dependency.
- For provider updates, keep compatibility with the current resource style and OCI versions.
- For new outputs, include descriptions and check downstream consumers.
- For new Kubernetes add-ons, prefer Helm releases and keep resource requests/limits modest.
- For new application features, keep defaults compatible with the free-tier ARM cluster.
- For DNS, TLS, and ingress changes, keep ingress-nginx, cert-manager, and the NLB flow aligned.

## Task-specific guidance

### Root cluster

- Preserve `kubeadm` as the cluster bootstrap mechanism.
- Preserve the control-plane/worker split in `local.nodes`.
- Keep generated private keys and kubeconfig handling local to the repository workflow.
- When changing package repositories or Kubernetes versions, check compatibility among kubeadm, kubelet, kubectl, Docker/containerd, and Weave CNI.
- If changing `http_backend_port` or `https_backend_port`, update NLB behavior through root outputs and `/nlb` consumers.

### Cloud-init

- Keep control-plane-only and worker-only dynamic parts separate.
- Preserve NFS setup on the control-plane node unless replacing the storage strategy is explicitly requested.
- Preserve Helm installation before Helm-managed add-ons.
- Be careful with nested heredocs in Terraform heredocs, especially the inline `kubectl apply` for the cert-manager `ClusterIssuer`.

### NLB

- Keep listeners on ports 80 and 443 unless the task explicitly changes the public interface.
- Keep backend ports aligned with ingress-nginx NodePorts from root remote state.
- Use `-parallelism=1` for NLB apply/destroy guidance when OCI reports invalid state transitions.

### PostgreSQL and n8n

- PostgreSQL is installed by Helm in the `postgresql` namespace by default.
- The n8n database initializer is a local Helm chart under `/postgresql/n8n_db`; edit templates there rather than embedding large manifests in Terraform.
- n8n uses an external PostgreSQL database, `nfs-dynamic` persistence, ingress-nginx, cert-manager TLS, and a separate Python runner Deployment.
- Do not place database passwords directly in values files or documentation. Keep them generated and stored in Kubernetes Secrets.

### PowerShell helpers

- Preserve `Set-StrictMode -Version Latest`, `$ErrorActionPreference = "Stop"`, and UTF-8 console setup.
- Preserve the OCI session authentication prompts that instruct the user to use the `DEFAULT` profile.
- Preserve backend discovery from `backend.hcl` and state files unless replacing the backend workflow is explicitly requested.
- Avoid destructive cleanup in helper scripts unless the user explicitly requests it.

## Change validation

- For documentation-only changes, validate by rereading the changed docs for accuracy against the repository.
- For Terraform changes, run `terraform fmt` in the affected stack. Use `terraform fmt -recursive` for multi-stack edits.
- Run `terraform validate` when the stack has been initialized and validation will not require unavailable credentials or network access.
- Confirm that use of `local` and `for_each` remains coherent.
- If suggesting resource removal, check that no outputs or dependent references remain.
- For Helm chart template changes, inspect rendered indentation mentally or with Helm tooling if available.
- For script changes, run PowerShell syntax checks when practical.

## When answering feature questions

- Be direct and concise.
- Use project terms: `OCI`, `kubeadm`, `cloud-init`, `kubeconfig`, `terraform apply`, `terraform destroy`, `ingress-nginx`, `cert-manager`, `NLB`, `NFS provisioner`, `Helm`.
- Explain risks: the project is not for production, Kubernetes `LoadBalancer` services stay pending without the OCI cloud controller, storage is NFS on the control-plane node, and public security rules are permissive.
- Mention the relevant stack directory when the answer involves optional components.

## Examples of accepted instructions

- "Update `README.md` to reflect the Ubuntu version and detail the `terraform apply` command."
- "Add an optional variable for `availability_domain` and document usage in the README."
- "Fix `cloud-init` syntax in `cloudinit.tf` while preserving Docker and Kubernetes installation."
- "Adjust the ingress NodePorts and keep `/nlb` aligned through remote state."
- "Update the n8n Helm values while preserving external PostgreSQL and TLS."
- "Add an output needed by a downstream stack and update the consumer."

## Examples of not accepted instructions

- "Rewrite the entire project as a reusable Terraform module."
- "Switch to OKE or another managed service."
- "Include a full observability dashboard or CI/CD pipeline without explicit request."
- "Move all stacks into one Terraform state without a migration plan."
- "Replace generated Secrets with hardcoded passwords."
