#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

COMPOSE_DIR="/srv/infrastructure/compose/development/git-server"
DATA_DIR="/srv/persistent/git/git-server"
BACKUP_DIR="${1:-/srv/backups/git-server}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="git-server-${TIMESTAMP}.tar.gz"

TMP_FILE=""
RESTART_REQUIRED=0

cd "$COMPOSE_DIR"

cleanup() {
    local status=$?
    trap - EXIT INT TERM HUP

    if [[ -n "$TMP_FILE" ]]; then
        rm -f -- "$TMP_FILE"
    fi

    if (( RESTART_REQUIRED )); then
        echo "Starting git-server..."
        if ! docker compose -f docker-compose.yml start git; then
            echo "ERROR: Could not restart git-server" >&2
            status=1
        fi
    fi

    exit "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

if (( EUID != 0 )); then
    echo "ERROR: Run as root" >&2
    exit 1
fi

for dir in "$COMPOSE_DIR" "$DATA_DIR"; do
    [[ -d "$dir" ]] || {
        echo "ERROR: Missing directory: $dir" >&2
        exit 1
    }
done

mkdir -p "$BACKUP_DIR"

# Prevent concurrent executions.
exec 9>"$BACKUP_DIR/.backup.lock"
flock -n 9 || {
    echo "ERROR: Another backup is running" >&2
    exit 1
}

STATE="$(docker inspect -f '{{.State.Running}}' git-server)"

if [[ "$STATE" == "true" ]]; then
    RESTART_REQUIRED=1
    echo "Stopping git-server..."
    docker compose -f docker-compose.yml stop git
fi

TMP_FILE="$(mktemp "$BACKUP_DIR/.git-server-XXXXXXXX.tar.gz")"

echo "Creating $ARCHIVE..."

tar -czpf "$TMP_FILE" \
    -C / \
    "${COMPOSE_DIR#/}" \
    "${DATA_DIR#/}"

echo "Validating archive..."
gzip -t "$TMP_FILE"
tar -tzf "$TMP_FILE" >/dev/null

if [[ -e "$BACKUP_DIR/$ARCHIVE" ]]; then
    echo "ERROR: Archive already exists" >&2
    exit 1
fi

mv -- "$TMP_FILE" "$BACKUP_DIR/$ARCHIVE"
TMP_FILE=""

(
    cd "$BACKUP_DIR"
    sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
)

echo "Backup completed:"
ls -lh "$BACKUP_DIR/$ARCHIVE"
