# Agent Instructions for Ampernetacle Plus

This root `AGENTS.md` file is the entry point for LLMs working on this repository.
The detailed agent rules and coding patterns are separated into Markdown files under the `/docs` directory.

ALWAYS reference the relevant .md file BEFORE generating any code.
ALWAYS write the documentation in ENGLISH.

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
- verify changes with `terraform fmt` and respect existing modular structure
- maintain clarity of educational purpose while supporting experimental features

## Notes

- The repository is not currently divided into separate Terraform modules; all configuration lives in the root.
- Kubernetes add-ons (Ingress, cert-manager, NFS provisioner) are installed via Helm during cluster bootstrap.
- The `/docs` content is the source of truth for agent instructions.
- All new agent instruction files for this project should be added under `/docs`.
- The project scope has expanded to include observability and networking features, but maintains free-tier compatibility.
