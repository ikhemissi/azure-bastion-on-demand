# Verification

What was checked, how and when, phase by phase. The README states only what this page shows, or says "expected" and why.

| # | Check | Phase | How | Result |
|---|---|---|---|---|
| V1 | Private endpoints and the internal web app resolve to private addresses on the jumpbox | 1 | `az vm run-command` on the jumpbox (no Bastion or internet needed): `getent hosts`, `curl`; the same from the laptop | **verified 2026-11-16:** on the jumpbox, Key Vault resolves to its private endpoint (10.40.2.4) and answers a token of the VM's identity with `ForbiddenByRbac` (the network lets it through; the identity has no role); the web app resolves to the environment's static IP (10.40.3.17) and answers 200 (23 s while it scales from zero, then 27 ms); the internet is unreachable (no NAT Gateway outside sessions). From the laptop, the web app's name doesn't resolve and Key Vault refuses a signed-in request: "Public network access is disabled". |
| V2 | The jumpbox has no public IP and accepts SSH from the Bastion subnet only | 1 | the NIC and the network security group's rules | **verified 2026-11-16:** no public IP on the VM (`az vm show -d`); inbound rules: SSH from 10.40.0.0/26 (the Bastion subnet), then deny all; the subnet is private (no default outbound access). |
| V3 | Creating a Bastion Standard host with its NAT Gateway, and deleting both: durations | 2 | `make bastion-up` / `bastion-down`, timed | pending |
| V4 | SSH from the laptop with Entra ID (`az network bastion ssh --auth-type AAD`), no SSH key | 2 | a session | pending |
| V5 | The tunnel, VS Code Remote-SSH, file transfer | 2 | a session | pending |
| V6 | `ssh -L` to Key Vault's private endpoint, `ssh -D` with `socks5h` for a browser, `curl`, the Azure CLI and `kubectl` | 2 | a session | pending |
| V7 | The reaper's least-privilege role suffices to delete a host and its NAT Gateway and to deallocate the jumpbox | 3 | the function's logs and the activity log | pending |
| V8 | The reaper deletes an expired host within 15 minutes, spares an extended one, and deletes an untagged one | 3 | three hosts in turn | pending |
| V9 | The cost of a session and of an idle day | 4 | Cost Management | pending |
