#!/usr/bin/env bash
set -Eeuo pipefail

export TF_IN_AUTOMATION=1

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

invoke_oci_session_authenticate() {
  local status

  printf 'Executing: oci session authenticate\n'
  printf 'Choose the region and complete the browser authentication flow.\n'
  printf "When the OCI CLI prompts for the profile name, type 'DEFAULT' and press Enter.\n"

  set +e
  oci session authenticate
  status=$?
  set -e

  if (( status != 0 )); then
    printf 'Command failed with exit code %s: oci session authenticate\n' "${status}" >&2
    exit "${status}"
  fi
}

invoke_terraform_command() {
  local status

  printf 'Executing: terraform'
  printf ' %q' "$@"
  printf '\n'

  set +e
  terraform "$@"
  status=$?
  set -e

  if (( status != 0 )); then
    printf 'Command failed with exit code %s: terraform' "${status}" >&2
    printf ' %q' "$@" >&2
    printf '\n' >&2
    exit "${status}"
  fi
}

get_hcl_string_value() {
  local path="$1"
  local name="$2"
  local value

  value="$(sed -nE "s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/p" "${path}" | head -n 1)"

  if [[ -z "${value}" ]]; then
    printf "Could not find HCL string value '%s' in %s\n" "${name}" "${path}" >&2
    exit 1
  fi

  printf '%s\n' "${value}"
}

invoke_postgresql_terraform_destroy() {
  local root_path
  local backend_path
  local state_path
  local bucket_name
  local oci_namespace
  local core_key

  root_path="$(cd "${script_dir}/.." && pwd -P)"
  backend_path="${root_path}/backend.hcl"
  state_path="${root_path}/state.tf"

  bucket_name="$(get_hcl_string_value "${backend_path}" "bucket")"
  oci_namespace="$(get_hcl_string_value "${backend_path}" "namespace")"
  core_key="$(get_hcl_string_value "${state_path}" "key")"

  export TF_VAR_bucket="${bucket_name}"
  export TF_VAR_oci_namespace="${oci_namespace}"
  export TF_VAR_core_key="${core_key}"

  cd "${script_dir}"

  invoke_oci_session_authenticate

  invoke_terraform_command \
    init \
    "-backend-config=bucket=${bucket_name}" \
    "-backend-config=namespace=${oci_namespace}"

  invoke_terraform_command destroy
}

invoke_postgresql_terraform_destroy
