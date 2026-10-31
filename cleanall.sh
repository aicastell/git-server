#!/bin/sh
set -eu

cd "$(dirname "$0")"

docker compose down
docker image rm alpine:git-server
