# Agent Instructions for Ampernetacle Plus

This root `AGENTS.md` file is the entry point for LLMs working on this repository.
Detailed agent rules, architecture notes, task workflows, and validation expectations live in Markdown files under the `/docs` directory.

ALWAYS reference the relevant `.md` file in `/docs` BEFORE generating or changing any code.
ALWAYS write project documentation and agent guidance in ENGLISH.

## Project purpose

This repository is a Terraform configuration for deploying a small Kubernetes cluster on Oracle Cloud Infrastructure (OCI) using `kubeadm`.
The default deployment creates:
- 4 virtual machines
- Ubuntu 22.04 images
- an ARM-based default shape (`VM.Standard.A1.Flex`)
- a multi-node cluster with one control plane and worker nodes
- an NGINX Ingress Controller with HTTP/HTTPS load balancing (via NLB)
- cert-manager with Let's Encrypt for automatic SSL/TLS certificates
- an NFS provisioner for dynamic PersistentVolumes
- metrics-server for resource monitoring

The repository also contains optional Terraform stacks for:
- an OCI Network Load Balancer in `/nlb`
- PostgreSQL on Kubernetes in `/postgresql`
- an application database initializer chart in `/postgresql/n8n_db`
- n8n on Kubernetes in `/n8n`

The project is intended for learning, testing, and low-cost experimentation, not production use.

## Primary agent files

- `docs/terraform-agent-guidelines.md`
  - Coding conventions
  - Terraform patterns and repository constraints
  - Expected behavior for edits

- `docs/terraform-agent-tasks.md`
  - Specific task guidance for issue resolutions and feature changes
  - Validation and non-functional requirements

## How to use

1. Read `AGENTS.md` to understand the repository scope.
2. Open the relevant file under `/docs` for the actual detailed instructions.
3. Follow the repository conventions before editing any Terraform files.
4. Keep all agent guidance in `/docs`; do not add unrelated rules directly to this root file.

## Agent responsibilities

Agents should:
- preserve the Terraform design and free-tier-friendly defaults
- avoid introducing production-only architecture
- keep OCI provider versioning and existing resource patterns consistent
- respect Helm-based application patterns for managing Kubernetes add-ons
- respect the separate Terraform state boundaries for root, NLB, PostgreSQL, n8n database initialization, and n8n
- verify Terraform changes with `terraform fmt` for the affected stack and respect the existing directory structure
- maintain clarity of educational purpose while supporting experimental features

## Notes

- The root stack creates the OCI compartment, network, instances, cluster bootstrap, kubeconfig, and core outputs.
- Optional stacks under `/nlb`, `/postgresql`, `/postgresql/n8n_db`, and `/n8n` consume remote state from earlier stacks.
- Kubernetes add-ons (Ingress, cert-manager, NFS provisioner, metrics-server) are installed via Helm during cluster bootstrap.
- The `/docs` content is the source of truth for agent instructions.
- All new agent instruction files for this project should be added under `/docs`.
- The project scope has expanded to include observability and networking features, but maintains free-tier compatibility.
