#!/usr/bin/env bash
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


set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/3ds-presence/Presence3DS}"

BASE_DIR="$(pwd)"
INFO_DIR="$BASE_DIR/info"
RESULT_DIR="$BASE_DIR/result"
SRC_DIR="$BASE_DIR/src"

WAIT_MINUTES="${WAIT_MINUTES:-60}"
LAST_COMMIT_FILE="$INFO_DIR/last_commit.txt"

log() { echo "$*"; }

mkdir -p "$INFO_DIR" "$RESULT_DIR"

while true; do
    log "Checking last commit of $REPO_URL ..."
    REMOTE_HASH="$(git ls-remote "$REPO_URL" HEAD | awk '{print $1}' || true)"

    if [ -z "$REMOTE_HASH" ]; then
        log "Could not fetch remote hash; retrying in ${WAIT_MINUTES} min."
        sleep $((WAIT_MINUTES * 60))
        continue
    fi

    # --- Same as last built commit: sleep and retry ---
    if [ -f "$LAST_COMMIT_FILE" ] && [ "$(cat "$LAST_COMMIT_FILE")" = "$REMOTE_HASH" ]; then
        log "No new commit ($REMOTE_HASH). Sleeping ${WAIT_MINUTES} min."
        sleep $((WAIT_MINUTES * 60))
        continue
    fi

    log "New commit detected: $REMOTE_HASH"

    # --- Build: clone if absent, otherwise pull ---
    if [ ! -d "$SRC_DIR/.git" ]; then
        log "Cloning repository ..."
        git clone --depth 1 "$REPO_URL" "$SRC_DIR"
    else
        log "Pulling latest changes ..."
        git -C "$SRC_DIR" fetch --depth 1 origin HEAD
        git -C "$SRC_DIR" reset --hard FETCH_HEAD
    fi

    cd "$SRC_DIR"
    log "Building ..."
    make
    log "Copying boot.firm -> $RESULT_DIR/"
    cp boot.firm "$RESULT_DIR/boot.firm"
    chmod o+r "$RESULT_DIR/boot.firm"
    log "Cleaning ..."
    make clean

    printf '%s\n' "$REMOTE_HASH" > "$LAST_COMMIT_FILE"
    log "Done. Build saved. Sleeping ${WAIT_MINUTES} min."
    sleep $((WAIT_MINUTES * 60))
done