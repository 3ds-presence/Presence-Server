# Stage 1: Build the Rust backend
FROM docker.io/library/rust:1.97-slim-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
    
# Copy all sources
COPY ./activity_generator/Cargo.toml backend/activity_generator/Cargo.toml
COPY ./activity_generator/src backend/activity_generator/src

COPY ./presence-backend/Cargo.toml backend/presence-backend/Cargo.toml
COPY ./presence-backend/src backend/presence-backend/src

# Build the release binary
WORKDIR /app/backend/presence-backend

ARG DEBUG="false"
RUN mkdir -p target/output && \
    if [ "$DEBUG" = "true" ]; then \
      cargo build && \
      cp target/debug/presence-backend target/output/; \
    else \
      cargo build --release && \
      cp target/release/presence-backend target/output/; \
    fi

# Stage 2: Runtime image
FROM docker.io/library/debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY --from=builder /app/backend/presence-backend/target/output/presence-backend /app/presence-backend

EXPOSE 5555

CMD ["/app/presence-backend"]
