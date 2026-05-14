GHCR_USER ?= $(shell echo $$GHCR_USER)
REGISTRY  = ghcr.io/$(GHCR_USER)

.PHONY: build push dev down setup ansible-workstation telemetry build-ros2

build:
	docker compose build automata-base
	docker compose build automata-ml

push: build
	docker tag automata-base:latest $(REGISTRY)/automata-base:latest
	docker tag automata-ml:latest   $(REGISTRY)/automata-ml:latest
	docker push $(REGISTRY)/automata-base:latest
	docker push $(REGISTRY)/automata-ml:latest

dev:
	docker compose up -d automata-dev

down:
	docker compose down

# Provisions the workstation and then builds containers
setup: ansible-workstation build

ansible-workstation:
	cd infra/ansible && \
	ansible-playbook playbooks/workstation.yml --ask-become-pass

telemetry:
	$(MAKE) -C shared/telemetry_server run

build-ros2:
	docker exec -it automata-automata-dev-1 \
	  bash /workspace/scripts/build_ros2.sh
