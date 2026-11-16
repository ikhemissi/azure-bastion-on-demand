# AGENTS.md — Private Azure resources from your laptop, with Bastion on demand

This repository is a **public sample**: an Azure Bastion that exists only while you use it, a jumpbox, private endpoints to reach, and a function that deletes the Bastion when its time is up. Read [README.md](README.md) first, then [docs/DECISIONS.md](docs/DECISIONS.md).

## How the sample is built

- **Phases:** (1) the base: network, jumpbox, private targets; (2) Bastion on demand and what works from the laptop; (3) the reaper function; (4) measurements and documentation. Stop and report after each.
- **Evidence over opinion:** what was checked, how and when goes to [docs/verification.md](docs/verification.md), with the date and the versions. The README states only what was verified, or says "expected" and why.
- **Decisions:** a choice someone could question goes to [docs/DECISIONS.md](docs/DECISIONS.md), with its reason; a changed decision is a new line that supersedes the old one.
- **Ask before deciding** anything that changes the design, the cost or the security model; propose a default.

## Rules

- **Never commit secrets**, keys, tokens, tenant or subscription IDs, or real user data. Use your own Entra identity (Azure CLI) and managed identities; local settings go to `.env` (git-ignored).
- **Public content:** generalized and factual; customer, employer-internal and personal details stay out.
- **Commits:** conventional commits (`feat(infra): …`, `feat(reaper): …`, `docs: …`), ending with the trailer `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
- **At the end:** harvest the reusable learnings into the knowledge base (pitfalls, findings, decisions), generalized.

## Infrastructure

- **One Terraform root** (`infra/`, one state), one file per part of the architecture. The files from shared building blocks (`container-apps-environment.tf`, `key-vault.tf`, `monitoring.tf`, `main.tf`, `providers.tf`, …), the modules in `infra/modules/` and the hook steps in `infra/hooks/<event>/` stay as they are, so that their improvements can be merged in later. Put the sample's own resources in a new file of `infra/` (calling a module of `infra/modules/` where one fits), its settings as variables mapped in `infra/main.tfvars.json`, its outputs as azd values, and its steps in `infra/hooks/<event>/NN-<name>.sh`.
- **Before every `azd provision`:** `azd provision --preview` (one plan for the whole root) and read it: only expected adds and changes, no unexpected destroy. Module tests: `terraform init -backend=false && terraform test` in `infra/modules/<module>`.

## Code humans can maintain

Everything here must be maintainable by human developers, whoever (or whatever) wrote it. A developer new to the project understands a module in minutes and changes it with confidence.

- **Simple and explicit over clever:** no metaprogramming, hidden magic or generic frameworks; an abstraction only when a second real use exists.
- **One role per unit:** a module states its role in one or two lines at the top; a function does one thing and fits on a screen (about 40 lines), otherwise split it into named steps.
- **Names carry meaning:** domain words, full words, booleans that read as questions; no single letters except short loop indices.
- **Flat control flow:** early returns, named intermediate values, no dense one-liners or formatter opt-outs.
- **Comments explain why** (the decision, the constraint, a link to the design or ADR), never what the code already says.
- **Consistency beats preference:** follow the patterns already in the repository before introducing a new one.
- **Few dependencies:** ask before adding one; prefer the standard library and what is already used.
- **Tests read as documentation:** named after the behaviour or spec scenario they check; arrange, act, assert.
- **Read your diff as a reviewer before calling a change done;** if a piece cannot be explained simply, rewrite it.

## Known pitfalls

If `.fast-start/pitfalls.md` exists (local only, git-ignored: never commit, copy or quote it), read it before changing
infrastructure or services: it lists pitfalls known for this kind of project.

- A subscription may offer only some VM sizes in a region (no B-series on the test subscription): check `az vm list-skus -l <region>` before choosing one.
- A container image pinned by digest must use a digest the registry resolves: take it from a pull (`podman pull`, then `podman image inspect`), not from a `HEAD` request with an index `Accept` header (the registry answered `MANIFEST_UNKNOWN`).
- Some tenants add IP tags to new public IP addresses; Terraform then wants to replace them: `ignore_changes = [ip_tags]`.
Add a pitfall here every time something bites you, in one line: the symptom, then what to do.
