TF_DIR     = terraform/environments/prod
ANSIBLE_DIR = ansible

.PHONY: tf-init tf-plan tf-apply tf-destroy \
        ansible-workstation ansible-check \
        vault-edit vault-view

# ── Terraform ─────────────────────────────────────────────────────

tf-init:
	cd $(TF_DIR) && terraform init

tf-plan: tf-init
	cd $(TF_DIR) && terraform plan

tf-apply: tf-init
	cd $(TF_DIR) && terraform apply

tf-destroy:
	cd $(TF_DIR) && terraform destroy

# ── Ansible ───────────────────────────────────────────────────────

ansible-workstation:
	cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/workstation.yml --ask-become-pass

ansible-check:
	cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/workstation.yml --check --diff

# ── Vault ─────────────────────────────────────────────────────────

vault-edit:
	cd $(ANSIBLE_DIR) && ansible-vault edit vault/secrets.yml

vault-view:
	cd $(ANSIBLE_DIR) && ansible-vault view vault/secrets.yml
