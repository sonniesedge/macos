PLAYBOOK := playbook.yaml

.PHONY: help deps lint check run homebrew git macos shell dotfiles remove-chezmoi upgrade

help: ## Show this help
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

deps: ## Install required Ansible collections
	ansible-galaxy collection install -r requirements.yaml

lint: ## Syntax check and lint the playbook
	ansible-playbook $(PLAYBOOK) --syntax-check
	@command -v ansible-lint >/dev/null && ansible-lint || echo "ansible-lint not installed, skipping"

check: ## Dry run, showing what would change
	ansible-playbook $(PLAYBOOK) --check --diff

run: ## Apply the full playbook
	ansible-playbook $(PLAYBOOK) --diff

homebrew: ## Apply only the Homebrew role
	ansible-playbook $(PLAYBOOK) --tags homebrew --diff

git: ## Apply only the git role
	ansible-playbook $(PLAYBOOK) --tags git --diff

macos: ## Apply only the macOS defaults role
	ansible-playbook $(PLAYBOOK) --tags macos --diff

shell: ## Apply only the shell role
	ansible-playbook $(PLAYBOOK) --tags shell --diff

dotfiles: ## Apply only the dotfiles role (writes ~/.zshrc)
	ansible-playbook $(PLAYBOOK) --tags dotfiles --diff

remove-chezmoi: ## One-shot. Delete the old chezmoi repo, config, cache, and formula
	ansible-playbook $(PLAYBOOK) --tags chezmoi-cleanup -e chezmoi_remove=true --diff

upgrade: ## Apply the playbook and upgrade all Homebrew packages
	ansible-playbook $(PLAYBOOK) --diff -e homebrew_upgrade_all=true
