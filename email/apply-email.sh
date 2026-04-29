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

  printf 'Retrieving current OCI user OCID from DEFAULT profile...\n' >&2
  user_id="$(get_oci_profile_value "user" "optional")"

  if [[ -z "${user_id}" ]]; then
    user_id="$(get_current_user_id_from_security_token)"
  fi

  if [[ -z "${user_id}" ]]; then
    printf 'Current user OCID is empty. Ensure OCI CLI session is valid.\n' >&2
    exit 1
  fi

  printf '%s\n' "${user_id}"
}

get_oci_profile_value() {
  local name="$1"
  local mode="${2:-required}"
  local config_path="${OCI_CLI_CONFIG_FILE:-${HOME}/.oci/config}"
  local value

  if [[ ! -f "${config_path}" ]]; then
    printf 'OCI CLI config file not found at %s. Ensure OCI CLI session is authenticated.\n' "${config_path}" >&2
    exit 1
  fi

  value="$(
    sed -nE "
      /^\\[DEFAULT\\][[:space:]]*$/,/^\\[.*\\][[:space:]]*$/ {
        s/^[[:space:]]*${name}[[:space:]]*=[[:space:]]*([^[:space:]#;]+).*/\\1/p
      }
    " "${config_path}" | head -n 1
  )"

  if [[ -z "${value}" ]]; then
    if [[ "${mode}" == "optional" ]]; then
      return 0
    fi

    printf "Could not find '%s' in OCI CLI DEFAULT profile. Run oci session authenticate and choose the DEFAULT profile.\n" "${name}" >&2
    exit 1
  fi

  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"

  printf '%s\n' "${value}"
}

resolve_oci_path() {
  local path="$1"
  local config_path="${OCI_CLI_CONFIG_FILE:-${HOME}/.oci/config}"
  local config_dir

  case "${path}" in
    "~"/*)
      printf '%s/%s\n' "${HOME}" "${path#"~/"}"
      ;;
    /*)
      printf '%s\n' "${path}"
      ;;
    *)
      config_dir="$(cd "$(dirname "${config_path}")" && pwd -P)"
      printf '%s/%s\n' "${config_dir}" "${path}"
      ;;
  esac
}

get_current_user_id_from_security_token() {
  local token_path
  local resolved_token_path
  local user_id

  token_path="$(get_oci_profile_value "security_token_file")"
  resolved_token_path="$(resolve_oci_path "${token_path}")"

  if [[ ! -f "${resolved_token_path}" ]]; then
    printf 'OCI security token file not found at %s. Run oci session authenticate again.\n' "${resolved_token_path}" >&2
    exit 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    user_id="$(python3 -c '
import base64
import json
import re
import sys

token_path = sys.argv[1]
token = open(token_path, "r", encoding="utf-8").read().strip()
parts = token.split(".")
if len(parts) < 2:
    sys.exit(2)

payload = parts[1] + "=" * (-len(parts[1]) % 4)
data = json.loads(base64.urlsafe_b64decode(payload.encode("ascii")).decode("utf-8"))

def find(value):
    if isinstance(value, str) and re.match(r"^ocid1\.user\.", value):
        return value
    if isinstance(value, dict):
        for item in value.values():
            result = find(item)
            if result:
                return result
    if isinstance(value, list):
        for item in value:
            result = find(item)
            if result:
                return result
    return None

result = find(data)
if not result:
    sys.exit(3)
print(result)
' "${resolved_token_path}")"
  else
    printf 'python3 is required to read the OCI user OCID from the security token when the DEFAULT profile has no user value.\n' >&2
    exit 1
  fi

  printf '%s\n' "${user_id}"
}

get_oci_profile_region() {
  local region

  printf 'Retrieving OCI region from DEFAULT profile...\n' >&2
  region="$(get_oci_profile_value "region")"

  if [[ -z "${region}" ]]; then
    printf 'Could not find region in OCI CLI DEFAULT profile. Run oci session authenticate and choose a region.\n' >&2
    exit 1
  fi

  printf '%s\n' "${region}"
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

  region="$(get_oci_profile_region)"
  export TF_VAR_region="${region}"

  invoke_terraform_command \
    init \
    "-backend-config=bucket=${bucket_name}" \
    "-backend-config=namespace=${oci_namespace}" \
    "-backend-config=auth=SecurityToken" \
    "-backend-config=config_file_profile=DEFAULT" \
    "-backend-config=region=${region}"

  invoke_terraform_command apply
}

invoke_email_terraform_apply
