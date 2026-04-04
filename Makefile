PREFIX ?= /usr/local
INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: install uninstall lint test help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install codex-rotate to ~/.local/bin
	@mkdir -p $(INSTALL_DIR)
	@cp bin/codex-rotate $(INSTALL_DIR)/codex-rotate
	@chmod +x $(INSTALL_DIR)/codex-rotate
	@echo "Installed codex-rotate to $(INSTALL_DIR)/codex-rotate"

uninstall: ## Remove codex-rotate from ~/.local/bin
	@rm -f $(INSTALL_DIR)/codex-rotate
	@echo "Removed codex-rotate from $(INSTALL_DIR)/codex-rotate"

lint: ## Run ShellCheck on all scripts
	shellcheck bin/codex-rotate
	shellcheck install.sh

test: ## Run basic smoke tests
	@echo "Running smoke tests..."
	@bash bin/codex-rotate help > /dev/null && echo "PASS: help command" || echo "FAIL: help command"
	@echo "All smoke tests completed"
