#!/usr/bin/env bash
# Ends the session now: deletes the Bastion host and the NAT Gateway (detached from the jumpbox's subnet first), then
# deallocates the jumpbox, which keeps only its disk.
#   scripts/bastion-down.sh [--keep-jumpbox]
set -euo pipefail
# shellcheck source=scripts/session-settings.sh
source "$(dirname "${BASH_SOURCE[0]}")/session-settings.sh"

step "Bastion host"
started=$(date +%s)
az network bastion delete -g "$RESOURCE_GROUP" -n "$BASTION_NAME" -o none 2>/dev/null || echo "none to delete"
echo "done in $(($(date +%s) - started)) s"

step "NAT Gateway"
az network vnet subnet update -g "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" -n "$JUMPBOX_SUBNET_NAME" \
  --remove natGateway -o none
az network nat gateway delete -g "$RESOURCE_GROUP" -n "$NAT_GATEWAY_NAME" -o none

if [[ "${1:-}" == "--keep-jumpbox" ]]; then
  echo "The jumpbox keeps running."
else
  step "Jumpbox (deallocated)"
  az vm deallocate -g "$RESOURCE_GROUP" -n "$JUMPBOX_NAME" -o none
fi
