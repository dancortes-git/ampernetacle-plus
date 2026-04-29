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

get_current_user_id() {
  local user_id
  local status

  printf 'Retrieving current OCI user OCID...
'

  set +e
  user_id="$(oci iam user get-current-user --query 'data.id' --raw-output 2>/dev/null)"
  status=$?
  set -e

  if (( status != 0 )); then
    printf 'Could not retrieve current user OCID. Ensure OCI CLI is installed and authenticated.\n' >&2
    exit 1
  fi

  if [[ -z "${user_id}" ]]; then
    printf 'Current user OCID is empty. Ensure OCI CLI session is valid.\n' >&2
    exit 1
  fi

  printf '%s\n' "${user_id}"
}

invoke_email_terraform_apply() {
  local root_path
  local backend_path
  local root_state_path
  local bucket_name
  local oci_namespace
  local root_key

  root_path="$(cd "${script_dir}/.." && pwd -P)"
  backend_path="${root_path}/backend.hcl"
  root_state_path="${root_path}/state.tf"

  bucket_name="$(get_hcl_string_value "${backend_path}" "bucket")"
  oci_namespace="$(get_hcl_string_value "${backend_path}" "namespace")"
  root_key="$(get_hcl_string_value "${root_state_path}" "key")"

  export TF_VAR_bucket="${bucket_name}"
  export TF_VAR_oci_namespace="${oci_namespace}"
  export TF_VAR_root_key="${root_key}"

  cd "${script_dir}"

  invoke_oci_session_authenticate

  smtp_user_id="$(get_current_user_id)"
  export TF_VAR_smtp_user_id="${smtp_user_id}"

  invoke_terraform_command \
    init \
    "-backend-config=bucket=${bucket_name}" \
    "-backend-config=namespace=${oci_namespace}"

  invoke_terraform_command apply
}

invoke_email_terraform_apply
