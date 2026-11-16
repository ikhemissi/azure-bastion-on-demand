# Verification

What was checked, how and when, phase by phase. The README states only what this page shows, or says "expected" and why.

| # | Check | Phase | How | Result |
|---|---|---|---|---|
| V1 | Private endpoints and the internal web app resolve to private addresses on the jumpbox | 1 | `nslookup` and `curl` from the jumpbox | pending |
| V2 | The jumpbox has no public IP and accepts SSH from the Bastion subnet only | 1 | the NIC and the network security group's rules | pending |
| V3 | Creating a Bastion Standard host with its NAT Gateway, and deleting both: durations | 2 | `make bastion-up` / `bastion-down`, timed | pending |
| V4 | SSH from the laptop with Entra ID (`az network bastion ssh --auth-type AAD`), no SSH key | 2 | a session | pending |
| V5 | The tunnel, VS Code Remote-SSH, file transfer | 2 | a session | pending |
| V6 | `ssh -L` to Key Vault's private endpoint, `ssh -D` with `socks5h` for a browser, `curl`, the Azure CLI and `kubectl` | 2 | a session | pending |
| V7 | The reaper's least-privilege role suffices to delete a host and its NAT Gateway and to deallocate the jumpbox | 3 | the function's logs and the activity log | pending |
| V8 | The reaper deletes an expired host within 15 minutes, spares an extended one, and deletes an untagged one | 3 | three hosts in turn | pending |
| V9 | The cost of a session and of an idle day | 4 | Cost Management | pending |
