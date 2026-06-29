SHELL := /usr/bin/env bash

.PHONY: help validate lint test java-build render analyze-istio smoke diagnostics reset-cluster destroy-lab

help:
	@echo "Targets: validate lint test java-build render analyze-istio smoke diagnostics reset-cluster destroy-lab"

lint:
	@echo "Running markdown/yaml/shell lint (if installed)"
	@command -v markdownlint >/dev/null && markdownlint "**/*.md" || echo "markdownlint not installed"
	@command -v yamllint >/dev/null && yamllint . || echo "yamllint not installed"
	@command -v shellcheck >/dev/null && find scripts -name '*.sh' -print0 | xargs -0 -r shellcheck || echo "shellcheck not installed"

validate: lint
	@echo "Running kubeconform (if installed)"
	@command -v kubeconform >/dev/null && find kubernetes istio -name '*.yaml' -print0 | xargs -0 -r kubeconform -summary || echo "kubeconform not installed"

test:
	@echo "No repository-wide automated tests yet. Use module-specific smoke checks."

java-build:
	@if [ -f applications/spring-microservices/pom.xml ]; then cd applications/spring-microservices && mvn -B test; else echo "Spring modules not implemented yet"; fi

render:
	@echo "Render target reserved for future Helm/Kustomize modules"

analyze-istio:
	@command -v istioctl >/dev/null && istioctl analyze -A || echo "istioctl not installed"

smoke:
	@bash scripts/smoke/run-smoke-tests.sh

diagnostics:
	@bash scripts/diagnostics/collect-cluster-diagnostics.sh

reset-cluster:
	@echo "WARNING: this resets kubeadm state on the current node" && bash scripts/reset/reset-node.sh --confirm-reset

destroy-lab:
	@echo "WARNING: this removes Hyper-V lab VMs/switch/NAT only when explicitly confirmed"
	@pwsh -File hyperv/powershell/Remove-Lab.ps1 -ConfirmDestruction
