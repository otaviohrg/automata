GHCR_USER ?= $(shell echo $$GHCR_USER)
REGISTRY  = ghcr.io/$(GHCR_USER)

.PHONY: build push dev down setup telemetry build-ros2

build:
	docker compose build helix-base
	docker compose build helix-ml

push: build
	docker tag helix-base:latest $(REGISTRY)/helix-base:latest
	docker tag helix-ml:latest   $(REGISTRY)/helix-ml:latest
	docker push $(REGISTRY)/helix-base:latest
	docker push $(REGISTRY)/helix-ml:latest

dev:
	docker compose up -d helix-dev

down:
	docker compose down

# Delegates to infra/Makefile then builds containers
setup:
	$(MAKE) -C infra ansible-workstation
	$(MAKE) build

telemetry:
	$(MAKE) -C shared/telemetry_server run

build-ros2:
	docker exec -it helix-helix-dev-1 \
	  bash /workspace/scripts/build_ros2.sh

lint:
	pre-commit run --all-files
