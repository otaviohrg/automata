GHCR_USER ?=$(shell echo$$GHCR_USER)
REGISTRY  = ghcr.io/$(GHCR_USER)

.PHONY: build push dev down

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
