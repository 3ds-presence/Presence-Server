#!/bin/sh
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


# Daily rotation of this project's Docker logs.
#
# One folder per day (server local time): logs/YYYY-MM-DD/. A day folder may
# contain several archives when a manual rotation is triggered mid-day:
#   backend-1.json.log.xz   (manual rotation earlier that day)
#   backend-2.json.log.xz   (automatic rotation at midnight, rest of the day)
#
# Each rotation copies a container's current Docker log into the day folder,
# truncates the Docker file (it stays open, Docker keeps writing to it) and
# compresses the copy with maximum compression (xz -9e -T0). Day folders
# older than RETENTION_DAYS are deleted.
#
# Modes:
#   (none)   loop forever:
#               - mid-day: archive today's logs reaching MAX_SIZE_BYTES
#               - once a day: archive "yesterday" (marked .done)
#   once     rotate "today" now and exit — used by docker exec ... once
#
# ROTATE_DATE (YYYY-MM-DD) overrides the target date (e.g. for tests).
# MAX_SIZE_BYTES: archive a running log as soon as it reaches this size
# (bytes, default 15 MiB). Set to 0 to disable mid-day rotation.

set -u

LOG_DIR="${LOG_DIR:-/logs}"
CONTAINERS_DIR="${CONTAINERS_DIR:-/var/lib/docker/containers}"
RETENTION_DAYS="${RETENTION_DAYS:-90}"
WAIT_SECS="${WAIT_SECS:-60}"
MAX_SIZE_BYTES="${MAX_SIZE_BYTES:-15728640}"   # 15 MiB

MODE="${1:-loop}"

# --- Compose project name: read from our own config.v2.json ---
PROJECT=""
self_cfg="${CONTAINERS_DIR}/$(hostname)/config.v2.json"
[ -f "$self_cfg" ] && PROJECT="$(jq -r '.Config.Labels["com.docker.compose.project"] // ""' "$self_cfg" 2>/dev/null)"
[ -z "$PROJECT" ] && PROJECT="${COMPOSE_PROJECT_NAME:-}"

if [ -z "$PROJECT" ]; then
  echo "[service-logs] Could not determine the compose project, giving up." >&2
  sleep 3600
  exit 1
fi

# Next available part number for a container inside a day folder
next_part() {
  n=1
  while [ -e "$1/$2-$n.json.log.xz" ]; do n=$((n + 1)); done
  echo "$n"
}

# Archive one container's log file into a day folder (copy + truncate + xz)
archive_log() {
  name="$1"; logfile="$2"; dir="$3"
  [ -f "$logfile" ] && [ -s "$logfile" ] || return 0
  part="$(next_part "$dir" "$name")"
  archive="$dir/$name-$part.json.log"
  cp -p "$logfile" "$archive"
  truncate -s 0 "$logfile"
  xz -9e -T0 "$archive" 2>/dev/null || xz -9e "$archive"
}

# Retention: delete day folders older than RETENTION_DAYS (by name date)
retention() {
  cutoff="$(date -d "-${RETENTION_DAYS} days" +%s 2>/dev/null)"
  for d in "$LOG_DIR"/*/; do
    [ -d "$d" ] || continue
    day="$(basename "$d")"
    case "$day" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
        ds="$(date -d "$day" +%s 2>/dev/null)" || continue
        [ -n "$cutoff" ] && [ "$ds" -lt "$cutoff" ] && rm -rf "$d"
        ;;
    esac
  done
}

# Archive every project container log (that has content) into a day folder.
# mark_done=yes touches the .done marker (automatic yesterday rotation).
archive_folder() {
  dir="$1"; mark_done="$2"
  mkdir -p "$dir"
  for cfg in "$CONTAINERS_DIR"/*/config.v2.json; do
    [ -f "$cfg" ] || continue
    proj="$(jq -r '.Config.Labels["com.docker.compose.project"] // ""' "$cfg" 2>/dev/null)"
    [ "$proj" = "$PROJECT" ] || continue
    svc="$(jq -r '.Config.Labels["com.docker.compose.service"] // ""' "$cfg" 2>/dev/null)"
    [ "$svc" = "service-logs" ] && continue

    cdir="$(dirname "$cfg")"
    cid="$(basename "$cdir")"
    name="$(jq -r '.Name // ""' "$cfg" 2>/dev/null | tr -d '/')"
    [ -z "$name" ] && continue
    archive_log "$name" "$cdir/$cid-json.log" "$dir"
  done
  [ "$mark_done" = "yes" ] && touch "$dir/.done"
  retention
}

# Archive a container's log as soon as it reaches MAX_SIZE_BYTES,
# into today's folder (mid-day rotation in loop mode).
archive_oversized() {
  [ "$MAX_SIZE_BYTES" -gt 0 ] || return 0
  today="$(date +%F)"
  dir="$LOG_DIR/$today"
  mkdir -p "$dir"
  for cfg in "$CONTAINERS_DIR"/*/config.v2.json; do
    [ -f "$cfg" ] || continue
    proj="$(jq -r '.Config.Labels["com.docker.compose.project"] // ""' "$cfg" 2>/dev/null)"
    [ "$proj" = "$PROJECT" ] || continue
    svc="$(jq -r '.Config.Labels["com.docker.compose.service"] // ""' "$cfg" 2>/dev/null)"
    [ "$svc" = "service-logs" ] && continue

    cdir="$(dirname "$cfg")"
    cid="$(basename "$cdir")"
    name="$(jq -r '.Name // ""' "$cfg" 2>/dev/null | tr -d '/')"
    [ -z "$name" ] && continue
    logfile="$cdir/$cid-json.log"
    [ -f "$logfile" ] && [ -s "$logfile" ] || continue

    size="$(wc -c < "$logfile" | tr -d ' ')"
    [ -n "$size" ] && [ "$size" -ge "$MAX_SIZE_BYTES" ] && archive_log "$name" "$logfile" "$dir"
  done
  retention
}

echo "[service-logs] project=$PROJECT mode=$MODE retention=${RETENTION_DAYS}d max_size=${MAX_SIZE_BYTES}B compression=xz-9e"

case "$MODE" in
  once)
    target="${ROTATE_DATE:-$(date +%F)}"
    echo "[service-logs] target=$target"
    archive_folder "$LOG_DIR/$target" no
    exit 0
    ;;
  *)
    while true; do
      # 1) Mid-day rotation: archive today's logs exceeding MAX_SIZE_BYTES
      archive_oversized
      # 2) Daily rotation of yesterday (once per day, marked .done)
      target="$(date -d '-1 day' +%F 2>/dev/null)"
      [ -n "$target" ] || target="$(date +%F)"
      archive_folder "$LOG_DIR/$target" yes
      sleep "$WAIT_SECS"
    done
    ;;
esac
