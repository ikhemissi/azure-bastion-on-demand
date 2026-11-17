# Reach resources in another virtual network

The jumpbox reaches what its virtual network reaches. To work with private resources that live in an existing virtual network (a database, a storage account, a cluster behind private endpoints), peer that network with the sample's and give the jumpbox their private DNS names. The Bastion, the jumpbox and the reaper don't change.

Checked on 2026-11-17 with a storage account whose only access is a private endpoint in another virtual network, with its own `privatelink.blob.core.windows.net` zone ([verification](verification.md) V10).

## Before you start

- **Address spaces must not overlap.** The sample uses `10.40.0.0/16` (`infra/network.tf`); change it before the first `azd provision` if your network uses it.
- **Permissions:** to create a peering, you need write access to the virtual network it starts from and the `peer` permission on the other one (Network Contributor on both covers it). Across subscriptions, use the remote network's full resource ID; across tenants, you need access in both.
- **The sample targets:** keep `DEPLOY_SAMPLE_TARGETS` off (the default). With it on, the sample has its own `privatelink.vaultcore.azure.net` zone, and a virtual network can be linked to only one zone of a name: Azure refuses the second link ("A virtual network cannot be linked to multiple zones with overlapping namespaces").

## 1. Peer the two networks

A peering has two halves, one on each side; traffic flows once both exist.

```bash
SAMPLE_RG=$(azd env get-value AZURE_RESOURCE_GROUP)
SAMPLE_VNET=$(azd env get-value VNET_NAME)
EXISTING_RG=<your resource group>
EXISTING_VNET=<your virtual network>

sample_id=$(az network vnet show -g "$SAMPLE_RG" -n "$SAMPLE_VNET" --query id -o tsv)
existing_id=$(az network vnet show -g "$EXISTING_RG" -n "$EXISTING_VNET" --query id -o tsv)

az network vnet peering create -g "$SAMPLE_RG" --vnet-name "$SAMPLE_VNET" -n to-existing \
  --remote-vnet "$existing_id" --allow-vnet-access
az network vnet peering create -g "$EXISTING_RG" --vnet-name "$EXISTING_VNET" -n to-bastion-sample \
  --remote-vnet "$sample_id" --allow-vnet-access

az network vnet peering show -g "$SAMPLE_RG" --vnet-name "$SAMPLE_VNET" -n to-existing \
  --query "{state: peeringState, sync: peeringSyncLevel}"   # Connected, FullyInSync
```

## 2. Resolve the private names

The jumpbox uses the DNS of its own virtual network, so it resolves your resources' public names until it sees your private DNS zones.

- **Private DNS zones** (the usual case): link each zone your resources use (`privatelink.blob.core.windows.net`, `privatelink.database.windows.net`, `privatelink.<region>.azmk8s.io`, …) to the sample's virtual network:

  ```bash
  az network private-dns link vnet create -g <zone's resource group> -z privatelink.blob.core.windows.net \
    -n bastion-sample -v "$sample_id" -e false
  ```

- **Your own DNS servers or a DNS Private Resolver:** set the sample network's DNS servers to them instead (`az network vnet update -g "$SAMPLE_RG" -n "$SAMPLE_VNET" --dns-servers <ip> …`), then restart the jumpbox so it picks them up.

## 3. Check from the jumpbox

During a session, or without one through `az vm run-command` (no Bastion or internet needed):

```bash
az vm run-command invoke -g "$SAMPLE_RG" -n "$(azd env get-value JUMPBOX_NAME)" --command-id RunShellScript \
  --scripts "getent hosts <account>.blob.core.windows.net; curl -s -o /dev/null -D - https://<account>.blob.core.windows.net/?comp=list | head -1"
```

The name must resolve to a private address of your network. In the check above, before the peering the account resolved to a public address and refused the request (403, its public access disabled); after it, to its private endpoint (`10.50.0.4`), which answered an unauthenticated request with 409 ("Public access is not permitted"), the account's own answer.

## What else to check

- **Network security groups and firewalls** on your side must allow the jumpbox's subnet (`10.40.1.0/27`), on the ports you use.
- **Hub and spoke:** peering is not transitive. Peer the sample with the network that holds the resources, or with the hub and route through its firewall (user-defined routes on the jumpbox subnet, and `--allow-forwarded-traffic`, `--use-remote-gateways` as your hub requires).
- **Clean up:** delete both halves when you no longer need them (`az network vnet peering delete …`) and the zone links you added. `azd down` deletes the sample's half and the sample's network, not your side.

Peering is charged per GB that crosses it, in each direction; idle, it costs nothing.
