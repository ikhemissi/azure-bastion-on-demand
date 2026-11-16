#!/usr/bin/env bash
# Installs the jumpbox's tools once, as root (run by `az vm run-command` from scripts/bastion-up.sh, during a session,
# when the NAT Gateway gives the jumpbox outbound access): the Azure CLI, azd and kubectl, from their publishers'
# package repositories and installer.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if command -v az >/dev/null && command -v azd >/dev/null && command -v kubectl >/dev/null; then
  echo "Tools already installed: az $(az version --query '"azure-cli"' -o tsv), azd $(azd version | awk '{print $2}'), kubectl $(kubectl version --client -o json | python3 -c 'import json,sys;print(json.load(sys.stdin)["clientVersion"]["gitVersion"])')"
  exit 0
fi

apt-get update -q
apt-get install -y -q ca-certificates curl gnupg jq unzip

# Azure CLI, from Microsoft's package repository.
curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash

# kubectl, from the Kubernetes project's package repository (one minor version line).
kubernetes_minor="v1.34"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/$kubernetes_minor/deb/Release.key" | gpg --dearmor -o /usr/share/keyrings/kubernetes.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/$kubernetes_minor/deb/ /" >/etc/apt/sources.list.d/kubernetes.list
apt-get update -q && apt-get install -y -q kubectl

# Azure Developer CLI, with its installer.
curl -fsSL https://aka.ms/install-azd.sh | bash

echo "Installed: az $(az version --query '"azure-cli"' -o tsv), azd $(azd version | awk '{print $2}'), kubectl $(kubectl version --client -o json | jq -r .clientVersion.gitVersion)"
