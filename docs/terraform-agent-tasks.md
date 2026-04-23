# Terraform Agent Task Instructions for Ampernetacle Plus

## Main task types

1. Terraform code fixes
2. Project documentation improvements
3. Configuration and variable updates
4. `cloud-init` adjustments and `kubeconfig` generation

## General approach

- Read the README and relevant `.tf` files before suggesting changes.
- Do not change the cluster's core architecture without an explicit reason.
- Keep the default behavior: 4 nodes, `VM.Standard.A1.Flex`, Ubuntu 22.04.
- If performance or additional support is needed, add optional settings via variables rather than replacing defaults.

## How to fix bugs

- Identify the correct Terraform file for the change.
- Verify that the change does not break other dependencies.
- Ensure formatting is consistent with `terraform fmt`.
- Add a brief comment only if it is needed to explain non-obvious behavior.

## How to handle new improvements

- For new variables, document them in `README.md` and `variables.tf`.
- For new OCI resources, confirm the object fits the current provisioning flow and has a clear dependency.
- For provider updates, keep compatibility with the current resource style and OCI versions.

## Change validation

- It is not required to run Terraform locally for this instruction file, but suggestions should be Terraform-consistent.
- Confirm that use of `local` and `for_each` remains coherent.
- If suggesting resource removal, check that no outputs or dependent references remain.

## When answering feature questions

- Be direct and concise.
- Use project terms: `OCI`, `kubeadm`, `cloud-init`, `kubeconfig`, `terraform apply`, `terraform destroy`.
- Explain risks: the project is not for production, `LoadBalancer` stays pending, there is no native ingress controller.

## Examples of accepted instructions

- "Update `README.md` to reflect the Ubuntu version and detail the `terraform apply` command."
- "Add an optional variable for `availability_domain` and document usage in the README."
- "Fix `cloud-init` syntax in `cloudinit.tf` while preserving Docker and Kubernetes installation."

## Examples of not accepted instructions

- "Rewrite the entire project as a reusable Terraform module."
- "Switch to OKE or another managed service."
- "Include a full observability dashboard or CI/CD pipeline without explicit request."
