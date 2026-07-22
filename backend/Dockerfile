# 3DS Presence — Discord Rich Presence for Nintendo 3DS
# Copyright (C) 2026 3DS Presence - LeonLeBreton
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
