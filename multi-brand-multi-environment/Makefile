BRAND ?=
ENV   ?=
DIR    = live/$(BRAND)/$(ENV)

BRANDS = brand-one brand-two
ENVS   = dev test preprod prod

.PHONY: check-args init import-theme plan apply destroy fmt validate plan-all

check-args:
ifndef BRAND
	$(error BRAND is required, e.g. make plan BRAND=brand-one ENV=dev)
endif
ifndef ENV
	$(error ENV is required, e.g. make plan BRAND=brand-one ENV=dev)
endif
	@test -d $(DIR) || { echo "No such tenant directory: $(DIR)"; exit 1; }

init: check-args
	terraform -chdir=$(DIR) init -backend-config=backend.hcl -reconfigure -input=false

import-theme: init
	terraform -chdir=$(DIR) import module.tenant.authsignal_theme.this ""

plan: init
	terraform -chdir=$(DIR) plan -lock-timeout=5m -input=false -out=tfplan

apply: check-args
	terraform -chdir=$(DIR) apply -lock-timeout=5m -input=false tfplan

destroy: init
	terraform -chdir=$(DIR) destroy -lock-timeout=5m -input=false

fmt:
	terraform fmt -recursive

validate:
	@for b in $(BRANDS); do for e in $(ENVS); do \
		echo "== validate $$b/$$e"; \
		terraform -chdir=live/$$b/$$e init -backend=false -input=false >/dev/null && \
		terraform -chdir=live/$$b/$$e validate || exit 1; \
	done; done

plan-all:
	@for b in $(BRANDS); do for e in $(ENVS); do \
		$(MAKE) plan BRAND=$$b ENV=$$e || exit 1; \
	done; done
