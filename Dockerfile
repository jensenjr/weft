# syntax=docker/dockerfile:1

# ---------------------------------------------------------------------------
# Stage 1: Install cargo-chef for dependency caching
# ---------------------------------------------------------------------------
FROM rust:1.93-slim-bookworm AS chef
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config libssl-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN cargo install cargo-chef
WORKDIR /app

# ---------------------------------------------------------------------------
# Stage 2: Generate the dependency recipe (invalidated only when Cargo.toml changes)
# ---------------------------------------------------------------------------
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ---------------------------------------------------------------------------
# Stage 3: Compile dependencies (cached layer)
# ---------------------------------------------------------------------------
FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

# Copy source and generate catalog-linked node modules before compiling
COPY . .
RUN bash scripts/catalog-link.sh --copy
RUN cargo build --release --bin weft-api --bin orchestrator --bin node-runner

# ---------------------------------------------------------------------------
# Stage 4: Minimal runtime image
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libgcc-s1 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/target/release/weft-api     /usr/local/bin/weft-api
COPY --from=builder /app/target/release/orchestrator  /usr/local/bin/orchestrator
COPY --from=builder /app/target/release/node-runner   /usr/local/bin/node-runner
