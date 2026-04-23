# Terraform Agent Guidelines for Ampernetacle Plus

## Repository purpose

This project provisions a Kubernetes cluster on Oracle Cloud Infrastructure (OCI) using Terraform and `kubeadm`.
The deployed infrastructure includes:

- 1 OCI compartment created by Terraform
- 1 VCN with an internet gateway
- 1 subnet with permissive security rules for learning
- multiple Ubuntu 22.04 instances
- `cloud-init` configuration to install Docker, Kubernetes, and bootstrap the cluster
- generation of a `kubeconfig` file

## Main patterns

- Use the OCI provider (`oracle/oci`) with a pinned version.
- Preserve the current resource conventions in `main.tf`, `network.tf`, `sshkey.tf`, `cloudinit.tf`, and `kubeconfig.tf`.
- Keep configurable values in `variables.tf`.
- Do not turn this repository into a production product. The focus is educational usability and a real cluster test environment.
- Favor clarity and simplicity over complex abstractions.

## Code conventions

- Use `terraform fmt` on changes.
- Preserve default names and values that enable free-tier execution.
- Do not introduce external modules or unnecessary abstractions without a clear rationale.
- If adding OCI resources, keep compatibility with the cluster creation flow and `kubeadm`.
- Avoid changes that alter the project purpose, such as migrating the cluster to OKE or adding a production application.

## Expected agent behavior

- When making changes, state the reason and keep comments minimal unless they add value.
- When updating resources, verify that Terraform names and dependencies remain functional.
- If adjusting `cloud-init`, preserve installation of Docker, kubeadm, kubelet, and kubectl.
- If modifying `kubeconfig.tf`, ensure the generated file references the correct public IP.

## Project-specific items

- `variables.tf` controls:
  - `name`
  - `shape`
  - `how_many_nodes`
  - `availability_domain`
  - `ocpus_per_node`
  - `memory_in_gbs_per_node`

- `providers.tf` specifies the required OCI provider version.
- `state.tf` configures the OCI backend for Terraform state storage.
- `network.tf` creates a simple network with a VCN, subnet, gateway, and open rules.
- `main.tf` creates instances and injects `cloud-init` through `metadata.user_data`.
- `sshkey.tf` generates the SSH key pair and stores the private key locally.
- `outputs.tf` provides SSH commands and other useful information after deployment.
- `kubeconfig.tf` transfers the kubeconfig from the control node to the project directory.

## Project limitations

- There is no OCI cloud controller installed; `LoadBalancer` remains in `Pending`.
- There is no ingress controller or storage class configured.
- The primary focus is delivering a basic multi-node cluster.

## When to create new agent files

- Add new files under `/docs` whenever there are task-specific rules.
- Use clear names, for example:
  - `docs/terraform-agent-tasks.md`
  - `docs/terraform-agent-guidelines.md`
  - `docs/terraform-agent-validation.md`
