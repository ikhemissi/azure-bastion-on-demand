# Daily use: a session opens the Bastion host and the jumpbox's NAT Gateway, and ends on its own after HOURS
# (the reaper, docs/DECISIONS.md D4) or with bastion-down. Run from the repository with the azd environment selected.
HOURS ?= 8
PORT ?= 2222

.PHONY: bastion-up bastion-extend bastion-down bastion-ssh bastion-tunnel test lint

bastion-up:  ## open a session that ends after HOURS (default 8)
	scripts/bastion-up.sh $(HOURS)

bastion-extend:  ## move the session's end HOURS later
	scripts/bastion-extend.sh $(HOURS)

bastion-down:  ## end the session now and deallocate the jumpbox (KEEP_JUMPBOX=1 to keep it running)
	scripts/bastion-down.sh $(if $(KEEP_JUMPBOX),--keep-jumpbox)

bastion-ssh:  ## SSH to the jumpbox with your Entra identity
	scripts/bastion-ssh.sh

bastion-tunnel:  ## the jumpbox's SSH on localhost:PORT, with an Entra certificate in .ssh/config
	scripts/bastion-tunnel.sh $(PORT)

test:  ## the reaper's unit tests, and Terraform's format and module tests (offline)
	dotnet test BastionReaper.slnx
	terraform -chdir=infra fmt -check -recursive
	for module in infra/modules/*/; do terraform -chdir=$$module init -backend=false -input=false >/dev/null && terraform -chdir=$$module test || exit 1; done

lint:  ## shellcheck
	shellcheck -x scripts/*.sh jumpbox/*.sh infra/hooks/*/*.sh
