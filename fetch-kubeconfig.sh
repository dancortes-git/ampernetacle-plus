#!/bin/bash

set -e

# Parameter validation
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <KubeHost> <KubeUser> <SshPrivateKeyFileName>"
  exit 1
fi

KUBE_HOST="$1"
KUBE_USER="$2"
SSH_KEY="$3"

KUBECONFIG_FILE="./kubeconfig"

echo "Retrieving kubeconfig from ${KUBE_USER}@${KUBE_HOST}"

# Copy the kubeconfig file from the remote host to the local machine
scp -o StrictHostKeyChecking=no -i "${SSH_KEY}" \
  "${KUBE_USER}@${KUBE_HOST}:~/.kube/config" \
  "${KUBECONFIG_FILE}"

# Replace the server address in the kubeconfig file with the Host IP
sed "s/10\.0\.0\.11/${KUBE_HOST}/g" "${KUBECONFIG_FILE}" > "${KUBECONFIG_FILE}.tmp"
mv "${KUBECONFIG_FILE}.tmp" "${KUBECONFIG_FILE}"

echo "Kubeconfig successfully retrieved"