# Repo tasks. shfmt, shellcheck and bashly come from the Brewfile; prettier from mise.toml.
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

FILES = git ls-files --cached --others --exclude-standard --deduplicate
# Shell sources shfmt formats. bin/dot is bashly output: format cli/, then `make build`.
SH_SRC := $(wildcard $(shell $(FILES) '*.sh' '*.bash' home/.bashrc home/.bash_profile))
# cli/ partials have no shebang and only make sense assembled, so shellcheck lints bin/dot instead.
SH_LINT := bin/dot $(filter-out cli/%,$(SH_SRC))
# Run on a fresh Mac before Homebrew bash exists: must parse with bash 3.2 (AGENTS.md rule 1).
SH_BOOTSTRAP := install.sh macos/defaults.sh
PRETTIER_SRC := $(wildcard $(shell $(FILES) '*.md' '*.yml' '*.yaml'))
PRETTIER := mise exec -- prettier --log-level warn
# Flags, not .editorconfig: home/.editorconfig (the global ~ one) has root = true and would govern home/.
SHFMT := shfmt -i 2

.PHONY: help build fmt lint check fmt-check build-check

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## Generate bin/dot from cli/ with bashly
	bashly generate --quiet

fmt: ## Format shell (shfmt), Markdown and YAML (prettier)
	$(SHFMT) -w $(SH_SRC)
	$(PRETTIER) --write $(PRETTIER_SRC)

lint: ## Lint shell (shellcheck) and parse bootstrap scripts with /bin/bash 3.2
	shellcheck $(SH_LINT)
	for f in $(SH_BOOTSTRAP); do /bin/bash -n "$$f"; done
	@! grep -rnE 'args\[--[a-z0-9]+( - [a-z0-9]+)+' cli || { echo 'cli/: shfmt split these flag keys; quote them (AGENTS.md rule 10)' >&2; exit 1; }

check: fmt-check lint build-check ## Everything CI would run; changes nothing

fmt-check:
	$(SHFMT) -d $(SH_SRC)
	$(PRETTIER) --check $(PRETTIER_SRC)

build-check:
	tmp=$$(mktemp -d); trap 'rm -rf "$$tmp"' EXIT; \
	BASHLY_TARGET_DIR="$$tmp" bashly generate --quiet; \
	cmp -s bin/dot "$$tmp/dot" || { echo 'bin/dot does not match cli/: run make build' >&2; exit 1; }
