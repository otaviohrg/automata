# Environment recovery guide
Last updated: 2026-05-13
Last tested: [date — update every time you verify this works end-to-end]

---

## Workstation recovery (fresh Arch install)

```bash
# 1. Install Ansible natively
sudo pacman -S ansible

# 2. Install required Ansible collections
ansible-galaxy collection install community.general kewlfft.aur

# 3. Create vault password file
# Password is stored in your password manager under "automata ansible vault"
echo "your-vault-password" > ~/.ansible_vault_pass
chmod 600 ~/.ansible_vault_pass

# 4. Clone the repo
git clone git@github.com:otaviohrg/automata.git
cd automata

# 5. Run workstation playbook — installs everything
# Enter your sudo password when prompted
make ansible-workstation

# 6. Verify idempotency — run twice, second run must show changed=0
make ansible-workstation

# 7. Build containers
make build

# 8. Recreate terraform.tfvars (gitignored — not in repo)
# Create infra/terraform/environments/prod/terraform.tfvars with:
#   github_token                  = ""
#   tailscale_actions_secret      = ""
#   tailscale_oauth_client_id     = ""
#   tailscale_oauth_client_secret = ""
#   tailnet                       = ""
# Values are in your password manager under "automata terraform"

# 9. Restore Terraform-managed resources
cd infra && make tf-init
make tf-apply
```

Total manual steps: vault password + `terraform.tfvars` recreation + 7 commands.

---

## Proxmox recovery (deferred — complete when server available)

```bash
# terraform apply -target=module.proxmox_vm
# make -C infra deploy-monitoring
# make -C infra tf-apply
# velero restore (month 14+)
```

---

## Raspberry Pi recovery

```bash
# Flash Raspberry Pi OS Lite to SD card first, then:
ansible-playbook infra/ansible/playbooks/raspberry-pi.yml \
  -i infra/ansible/inventory/hosts.yml \
  --limit wheeled_robot \
  --ask-become-pass
```

---

## Verification checklist after recovery

Run these in order — each depends on the previous passing.

### Native toolchain
- [ ] `nvidia-smi` shows GPU with correct driver version
- [ ] `nvcc --version` shows CUDA 12.x
- [ ] `docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi` works
- [ ] `uv --version` works
- [ ] `terraform --version` shows 1.7+
- [ ] `ansible --version` works
- [ ] `kubectl version --client` works
- [ ] `tailscale status` shows workstation authenticated

### Containers
- [ ] `docker compose run --rm automata-ml python3 -c "import torch; print(torch.cuda.is_available())"` → `True`
- [ ] `docker compose run --rm automata-base bash -lc "python3 -c 'import rclpy; import mujoco; print(\"both work\")'"` succeeds
- [ ] `docker compose run --rm automata-base bash -lc "echo \$VIRTUAL_ENV"` → `/opt/venv`
- [ ] Both images visible on GHCR

### Ansible idempotency
- [ ] Second run of `make ansible-workstation` shows `changed=0, failed=0`

### ROS2
- [ ] `make dev` starts `automata-dev` container
- [ ] `make build-ros2` completes without manual patching
- [ ] Inside `automata-dev`: `ros2 run learning_nodes joint_publisher` works
- [ ] In second terminal inside same container: `ros2 topic hz /joint_states` → ~50Hz

### Rust
- [ ] `rustc --version` works natively
- [ ] `cargo test` passes in `shared/firmware/` with zero warnings
- [ ] `cargo run --bin encoder_sim` prints simulation output

### Go
- [ ] `go run shared/telemetry_server/main.go` starts on `:50051` and `:9090`
- [ ] `curl localhost:9090/metrics | grep telemetry_messages_total` returns the metric
- [ ] `docker compose run --rm automata-base python3 /workspace/shared/telemetry_server/test_client.py` passes

### IaC
- [ ] `make -C infra tf-plan` runs without errors
- [ ] GitHub branch protection active on `main`
- [ ] Tailscale ACL visible in tailscale.com admin console
- [ ] `ansible-vault view infra/ansible/vault/secrets.yml` decrypts correctly
