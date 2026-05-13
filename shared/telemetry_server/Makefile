.PHONY: run stop proto test clean fmt

# Start the server natively
run:
	go run main.go

# Generate proto stubs (Go + Python via container)
proto:
	protoc \
		--go_out=. \
		--go-grpc_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_opt=paths=source_relative \
		proto/telemetry.proto
	docker compose run --rm automata-base bash -c \
		"python -m grpc_tools.protoc \
			-I /workspace/shared/telemetry_server \
			--python_out=/workspace/shared/telemetry_server \
			--grpc_python_out=/workspace/shared/telemetry_server \
			/workspace/shared/telemetry_server/proto/telemetry.proto"

# Run Go tests
test:
	go test -race ./...

# Run Python test client against a running server
test-client:
	docker compose run --rm automata-base \
		python3 /workspace/shared/telemetry_server/test_client.py

# Format and vet
fmt:
	go fmt ./...
	go vet ./...

# Remove generated proto files
clean:
	rm -f proto/*.pb.go proto/*_pb2*.py proto/__pycache__
