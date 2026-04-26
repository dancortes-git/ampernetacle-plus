# Terraform Agent Guidelines for Ampernetacle Plus

## Repository purpose

This project provisions a Kubernetes cluster on Oracle Cloud Infrastructure (OCI) using Terraform and `kubeadm`.
The root stack deploys:

- 1 OCI compartment created by Terraform
- 1 VCN with an internet gateway
- 1 public subnet with permissive security rules for learning
- multiple Ubuntu 22.04 compute instances
- `cloud-init` configuration to install Docker, Kubernetes, and bootstrap the cluster
- Weave CNI
- an NGINX Ingress Controller installed with Helm as a DaemonSet and exposed through NodePorts
- cert-manager with a Let's Encrypt `ClusterIssuer`
- metrics-server
- an NFS server on the control-plane node and an `nfs-dynamic` default StorageClass
- generation of a local `kubeconfig` file

Optional stacks in subdirectories extend the root cluster:

- `/nlb` creates an OCI Network Load Balancer that forwards ports 80 and 443 to the ingress-nginx NodePorts on all Kubernetes nodes.
- `/postgresql` installs Bitnami PostgreSQL in Kubernetes with a generated admin password.
- `/postgresql/n8n_db` is a local Helm chart plus Terraform wrapper that creates the n8n namespace, database user, database, and synchronized Kubernetes Secrets.
- `/n8n` installs n8n with the community Helm chart, external PostgreSQL, ingress, TLS, persistent storage, and an external Python task runner Deployment.

The project is for learning, testing, and low-cost experimentation. Do not reshape it into production infrastructure unless the user explicitly asks for that direction.

## Architecture and state boundaries

- The root directory is the core Terraform stack. It owns OCI identity, networking, compute instances, SSH keys, cloud-init, kubeconfig transfer, and core outputs.
- `/nlb` is a separate Terraform stack with its own backend key. It reads root remote state for the compartment, subnet, node IPs, and ingress backend ports.
- `/postgresql` is a separate Terraform stack with its own backend key. It reads root remote state and uses the generated kubeconfig to manage Kubernetes and Helm resources.
- `/postgresql/n8n_db` is a separate Terraform stack with its own backend key. It reads root and PostgreSQL remote state.
- `/n8n` is a separate Terraform stack with its own backend key. It reads `/postgresql/n8n_db` remote state.
- Keep these state boundaries intact. Do not merge the stacks, convert them into Terraform modules, or move resources between states without a clear migration plan requested by the user.
- The normal dependency order is: root stack, `/nlb`, `/postgresql`, `/postgresql/n8n_db`, then `/n8n`.

## Main patterns

- Use the OCI provider (`oracle/oci`) with a pinned version.
- Use pinned provider versions already present in each stack.
- Preserve the current root resource conventions in `main.tf`, `network.tf`, `sshkey.tf`, `cloudinit.tf`, and `kubeconfig.tf`.
- Keep configurable values in the nearest stack's `variables.tf`.
- Prefer outputs when another stack needs values. Optional stacks should consume values through `terraform_remote_state` rather than duplicating constants.
- Keep Helm-based Kubernetes add-ons in the existing Helm/provider pattern.
- Do not turn this repository into a production product. The focus is educational usability and a real cluster test environment.
- Favor clarity and simplicity over complex abstractions.

## Code conventions

- Use `terraform fmt` on changes.
- Preserve default names and values that enable free-tier execution.
- Do not introduce external modules or unnecessary abstractions without a clear rationale.
- If adding OCI resources, keep compatibility with the cluster creation flow and `kubeadm`.
- If adding Kubernetes resources, prefer the Terraform Kubernetes provider or Helm release pattern already used in the target stack.
- Use typed variables with descriptions for new variables.
- Use output descriptions for new outputs.
- Avoid hardcoding secrets. Use generated passwords and Kubernetes Secrets for credentials.
- Avoid changes that alter the project purpose, such as migrating the cluster to OKE or adding production-only architecture.

## Expected agent behavior

- When making changes, state the reason and keep comments minimal unless they add value.
- When updating resources, verify that Terraform names and dependencies remain functional.
- If adjusting `cloud-init`, preserve installation of Docker, kubeadm, kubelet, and kubectl.
- If modifying bootstrap add-ons in `cloudinit.tf`, preserve ingress-nginx, metrics-server, cert-manager, the Let's Encrypt `ClusterIssuer`, and the NFS provisioner unless the task explicitly changes them.
- If modifying `kubeconfig.tf`, ensure the generated file references the correct public IP.
- If changing a remote-state output, update all stacks that consume it.
- If touching PowerShell helper scripts, preserve strict mode, UTF-8 console setup, OCI session authentication guidance, and backend variable discovery.

## Project-specific items

Root `variables.tf` controls:

  - `name`
  - `description`
  - `shape`
  - `operating_system`
  - `operating_system_version`
  - `operating_system_username`
  - `how_many_nodes`
  - `availability_domain`
  - `ocpus_per_node`
  - `memory_in_gbs_per_node`
  - `http_backend_port`
  - `https_backend_port`
  - `email_cert_issuer`

Root file roles:

- `providers.tf` specifies the required OCI provider version.
- `state.tf` configures the OCI backend for Terraform state storage.
- `network.tf` creates a simple network with a VCN, subnet, gateway, and open rules.
- `main.tf` creates instances and injects `cloud-init` through `metadata.user_data`.
- `sshkey.tf` generates the SSH key pair and stores the private key locally.
- `outputs.tf` provides SSH commands, subnet/compartment IDs, ingress backend ports, and node IPs for downstream stacks.
- `kubeconfig.tf` transfers the kubeconfig from the control node to the project directory.
- `Apply.ps1` applies the root stack and then applies `/nlb`.
- `Destroy.ps1` destroys `/nlb` before destroying the root stack.

Optional stack file roles:

- `/nlb/nlb.tf` creates the OCI Network Load Balancer, backend sets, node backends, listeners, and public IP output.
- `/postgresql/main.tf` creates a namespace, generated password Secret, and Bitnami PostgreSQL Helm release.
- `/postgresql/n8n_db/main.tf` creates application database credentials and runs the local database-init Helm chart.
- `/n8n/main.tf` installs n8n and creates the external Python task runner resources.
- Each optional stack has its own `state.tf`, `providers.tf`, `variables.tf`, and helper apply/destroy scripts where applicable.

## Project limitations

- There is no OCI cloud controller installed; `LoadBalancer` remains in `Pending`.
- Ingress is provided by ingress-nginx using NodePorts and the optional OCI NLB stack, not by Kubernetes `Service` resources of type `LoadBalancer`.
- Storage is provided by an NFS provisioner hosted on the control-plane node. This is useful for experiments, not a highly available storage design.
- Security rules are intentionally permissive for learning and testing.
- The cluster is not production hardened.
- The primary focus is delivering a practical multi-node cluster and optional app platform components.

## Validation expectations

- Run `terraform fmt` for every stack touched. Use `terraform fmt -recursive` when changes span multiple stacks.
- Prefer `terraform validate` in the affected stack after `terraform init` is available.
- For Helm template changes under `/postgresql/n8n_db/templates`, check YAML indentation carefully.
- For `cloud-init` changes, check heredoc indentation, shell syntax, and ordering between control-plane and worker parts.
- Do not run destructive Terraform commands unless the user requested them.

## When to create new agent files

- Add new files under `/docs` whenever there are task-specific rules.
- Use clear names, for example:
  - `docs/terraform-agent-tasks.md`
  - `docs/terraform-agent-guidelines.md`
  - `docs/terraform-agent-validation.md`
