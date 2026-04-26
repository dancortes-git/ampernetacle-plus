#!/usr/bin/env bash
set -Eeuo pipefail

export TF_IN_AUTOMATION=1

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

repair_ssh_key_files() {
  local ssh_key_file
  local ssh_key_path

  for ssh_key_file in id_rsa id_rsa.pub; do
    ssh_key_path="${script_dir}/${ssh_key_file}"

    if [[ ! -e "${ssh_key_path}" ]]; then
      continue
    fi

    printf 'Normalizing permissions for %s\n' "${ssh_key_file}"

    if [[ "${ssh_key_file}" == "id_rsa" ]]; then
      chmod 600 "${ssh_key_path}"
    else
      chmod 644 "${ssh_key_path}"
    fi
  done
}

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

invoke_nlb_terraform_apply() {
  local backend_path="${script_dir}/backend.hcl"
  local state_path="${script_dir}/state.tf"
  local nlb_path="${script_dir}/nlb"
  local bucket_name
  local namespace
  local core_key

  bucket_name="$(get_hcl_string_value "${backend_path}" "bucket")"
  namespace="$(get_hcl_string_value "${backend_path}" "namespace")"
  core_key="$(get_hcl_string_value "${state_path}" "key")"

  export TF_VAR_bucket="${bucket_name}"
  export TF_VAR_namespace="${namespace}"
  export TF_VAR_core_key="${core_key}"

  (
    cd "${nlb_path}"

    invoke_oci_session_authenticate

    invoke_terraform_command \
      init \
      "-backend-config=bucket=${bucket_name}" \
      "-backend-config=namespace=${namespace}"

    invoke_terraform_command \
      apply \
      -parallelism=1
  )
}

cd "${script_dir}"

invoke_oci_session_authenticate

invoke_terraform_command \
  init \
  -backend-config=./backend.hcl

repair_ssh_key_files

invoke_terraform_command apply

invoke_nlb_terraform_apply
