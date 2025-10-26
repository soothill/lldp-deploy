# Makefile for LLDP Deployment with Ansible
# Usage: make <target>

# Variables
INVENTORY ?= inventory.ini
PLAYBOOK ?= deploy_lldp.yml
ANSIBLE_OPTS ?=
LIMIT ?=
EXTRA_VARS ?=

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

.PHONY: help install install-basic install-advanced check check-basic check-advanced \
        verify status neighbors info clean lint limit test-connection

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(BLUE)LLDP Deployment Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make install                              # Deploy basic LLDP"
	@echo "  make install-advanced                     # Deploy advanced LLDP with config"
	@echo "  make install ANSIBLE_OPTS='--ask-become-pass'  # Prompt for sudo password"
	@echo "  make check                                # Dry run to see what would change"
	@echo "  make limit LIMIT=server1                  # Deploy to specific host"
	@echo "  make verify                               # Check LLDP service status"
	@echo "  make neighbors                            # Show LLDP neighbors"

install: ## Deploy LLDP using basic playbook
	@echo "$(GREEN)Deploying LLDP to all hosts...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp.yml $(ANSIBLE_OPTS)

install-basic: install ## Alias for 'make install'

install-advanced: ## Deploy LLDP using advanced playbook with configuration
	@echo "$(GREEN)Deploying LLDP with advanced configuration...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp_advanced.yml $(ANSIBLE_OPTS)

install-custom: ## Deploy with custom configuration enabled
	@echo "$(GREEN)Deploying LLDP with custom configuration...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp_advanced.yml -e "lldp_custom_config=true" $(ANSIBLE_OPTS)

check: ## Dry run - show what would change (basic playbook)
	@echo "$(YELLOW)Running check mode (no changes will be made)...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp.yml --check --diff $(ANSIBLE_OPTS)

check-basic: check ## Alias for 'make check'

check-advanced: ## Dry run - show what would change (advanced playbook)
	@echo "$(YELLOW)Running check mode for advanced playbook...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp_advanced.yml --check --diff $(ANSIBLE_OPTS)

limit: ## Deploy to specific hosts (use: make limit LIMIT=hostname)
	@if [ -z "$(LIMIT)" ]; then \
		echo "$(YELLOW)Usage: make limit LIMIT=hostname$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Deploying LLDP to $(LIMIT)...$(NC)"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --limit $(LIMIT) $(ANSIBLE_OPTS)

test-connection: ## Test Ansible connectivity to all hosts
	@echo "$(GREEN)Testing connection to all hosts...$(NC)"
	ansible all -i $(INVENTORY) -m ping

verify: ## Verify LLDP service status on all hosts
	@echo "$(GREEN)Checking LLDP service status...$(NC)"
	ansible all -i $(INVENTORY) -m systemd -a "name=lldpd" -b || true

status: verify ## Alias for 'make verify'

neighbors: ## Show LLDP neighbors on all hosts
	@echo "$(GREEN)Displaying LLDP neighbors...$(NC)"
	ansible-playbook -i $(INVENTORY) show_neighbors.yml

info: ## Show LLDP chassis information on all hosts
	@echo "$(GREEN)Displaying LLDP chassis information...$(NC)"
	ansible-playbook -i $(INVENTORY) show_chassis.yml

restart: ## Restart LLDP service on all hosts
	@echo "$(YELLOW)Restarting LLDP service...$(NC)"
	ansible all -i $(INVENTORY) -m systemd -a "name=lldpd state=restarted" -b

stop: ## Stop LLDP service on all hosts
	@echo "$(YELLOW)Stopping LLDP service...$(NC)"
	ansible all -i $(INVENTORY) -m systemd -a "name=lldpd state=stopped" -b

start: ## Start LLDP service on all hosts
	@echo "$(GREEN)Starting LLDP service...$(NC)"
	ansible all -i $(INVENTORY) -m systemd -a "name=lldpd state=started" -b

logs: ## View LLDP service logs on all hosts
	@echo "$(GREEN)Fetching LLDP logs...$(NC)"
	ansible all -i $(INVENTORY) -m command -a "journalctl -u lldpd -n 50 --no-pager" -b

lint: ## Lint Ansible playbooks
	@echo "$(GREEN)Linting playbooks...$(NC)"
	@command -v ansible-lint >/dev/null 2>&1 || { echo "$(YELLOW)ansible-lint not found. Install with: pip install ansible-lint$(NC)"; exit 1; }
	ansible-lint deploy_lldp.yml
	ansible-lint deploy_lldp_advanced.yml

syntax: ## Check playbook syntax
	@echo "$(GREEN)Checking syntax...$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp.yml --syntax-check
	ansible-playbook -i $(INVENTORY) deploy_lldp_advanced.yml --syntax-check

list-hosts: ## List all hosts in inventory
	@echo "$(GREEN)Hosts in inventory:$(NC)"
	ansible all -i $(INVENTORY) --list-hosts

list-tasks: ## List all tasks in playbook
	@echo "$(GREEN)Tasks in basic playbook:$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp.yml --list-tasks

list-tasks-advanced: ## List all tasks in advanced playbook
	@echo "$(GREEN)Tasks in advanced playbook:$(NC)"
	ansible-playbook -i $(INVENTORY) deploy_lldp_advanced.yml --list-tasks

verbose: ## Run with verbose output (use: make install verbose)
	@$(MAKE) install ANSIBLE_OPTS="-v"

vv: ## Run with more verbose output
	@$(MAKE) install ANSIBLE_OPTS="-vv"

vvv: ## Run with maximum verbose output
	@$(MAKE) install ANSIBLE_OPTS="-vvv"

clean: ## Clean temporary files
	@echo "$(GREEN)Cleaning temporary files...$(NC)"
	find . -type f -name "*.retry" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete

requirements: ## Install Ansible requirements
	@echo "$(GREEN)Installing Ansible...$(NC)"
	@command -v ansible >/dev/null 2>&1 || { \
		echo "$(YELLOW)Ansible not found. Installing...$(NC)"; \
		pip install ansible; \
	}
	@echo "$(GREEN)Ansible is installed$(NC)"

uninstall: ## Remove LLDP from all hosts
	@echo "$(YELLOW)WARNING: This will remove LLDP from all hosts$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		ansible all -i $(INVENTORY) -m systemd -a "name=lldpd state=stopped enabled=no" -b; \
		ansible all -i $(INVENTORY) -m apt -a "name=lldpd state=absent" -b --limit 'ansible_os_family=Debian'; \
		ansible all -i $(INVENTORY) -m yum -a "name=lldpd state=absent" -b --limit 'ansible_os_family=RedHat'; \
	fi

backup-config: ## Backup LLDP configuration from all hosts
	@echo "$(GREEN)Backing up LLDP configurations...$(NC)"
	@mkdir -p backups
	ansible all -i $(INVENTORY) -m fetch -a "src=/etc/lldpd.d/ansible.conf dest=backups/ flat=no" -b || true

version: ## Show Ansible version
	@ansible --version
