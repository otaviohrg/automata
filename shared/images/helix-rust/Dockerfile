FROM rust:1.78-slim

RUN apt-get update && apt-get install -y \
    curl git pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install espup for ESP32 cross-compilation in CI
RUN cargo install espup && espup install

RUN rustup component add clippy rustfmt
RUN rustup target add riscv32imc-unknown-none-elf

WORKDIR /workspace
