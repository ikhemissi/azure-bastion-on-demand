# Questions

| # | Question | Experiments | Status |
|---|---|---|---|
| Q1 | Can Azure Bastion Standard, created on demand and deleted automatically when its time is up, give a developer secure access from their laptop to private resources in a virtual network (private DNS, kubectl, azd deploy, private web apps and data services) at a low cost? | 01– | open |
| Q2 | How long do creating and deleting a Bastion Standard host take, and what does a session cost (hourly rounding included)? | 02 | open |
| Q3 | From the laptop, which tasks work through the native client: SSH with Entra ID, the tunnel, VS Code Remote-SSH, `ssh -L` to a private endpoint, and `ssh -D` with remote DNS for a browser, `kubectl` and the Azure CLI? | 02 | open |
| Q4 | Do private endpoints' names resolve to private addresses on the jumpbox, and from the laptop through the SOCKS proxy (`socks5h`)? | 01, 02 | open |
| Q5 | Which least-privilege role lets an automated reaper delete a Bastion host and deallocate a VM? | 03 | open |
| Q6 | Does a timer-triggered function (Flex Consumption, .NET isolated, every 15 minutes) delete hosts whose `delete-after` time has passed, spare those whose time was extended, and delete untagged ones? | 03 | open |
| Q7 | What would Bastion Developer (free, portal only, one connection) and Basic offer instead? | documentation | open |

Status: `open`, `answered`, `partly answered`, `unanswered` (with what blocked it).
