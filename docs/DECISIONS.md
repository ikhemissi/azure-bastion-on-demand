# Decisions

Choices made for this spike, and why. Newest last; a decision that changes is superseded by a new line, not rewritten.

| # | Date | Decision | Why |
|---|---|---|---|
| D1 | 2026-11-16 | Access through **Azure Bastion Standard with native-client support**, to a Linux jumpbox in the virtual network. | It brings the laptop's own terminal and editor (Entra ID SSH, tunnels, VS Code Remote-SSH, SSH forwarding) where Developer offers a portal session only and Basic no native client ([SKU comparison](https://learn.microsoft.com/azure/bastion/bastion-sku-comparison)). Developer and Basic are documented, not tested (Q7). |
| D2 | 2026-11-16 | The Bastion host is **created on demand and deleted after use**, by scripts (`az`), not by Terraform. | A Bastion host can't be stopped and is charged per hour from deployment (0.2603 € an hour in francecentral, retail, November 2026: about 190 € a month always on). Kept out of Terraform so that its deletion is not drift that the next provision would undo. Terraform keeps what is permanent: the network with `AzureBastionSubnet`, the public IP, the jumpbox, the private endpoints and the reaper. |
| D3 | 2026-11-16 | Each host carries a **`delete-after` tag** (ISO 8601 UTC, e.g. `2026-11-16T19:40:00Z`), set at creation (default 8 hours later) and moved later by a script. | The time to delete travels with the resource, so the reaper needs no state of its own. |
| D4 | 2026-11-16 | A **reaper function** (Flex Consumption, .NET isolated, timer every 15 minutes) deletes each host whose time has passed, **and any host without a readable tag**, then deallocates the jumpbox. | A forgotten host costs about 6 € a day. Only this project's scripts create hosts in its resource group, so an untagged host is a mistake to remove. Deallocating the jumpbox leaves only its disk to pay. |
| D5 | 2026-11-16 | Private targets: **Key Vault** behind a private endpoint (a data service), and a sample web app in an **internal Container Apps environment** (a private web app). No container registry. | They cost almost nothing while idle. The web app's image comes from Microsoft's public registry, so the generated registry is removed. |
