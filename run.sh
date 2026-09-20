#!/bin/sh
set -eu

PROJECT_DIR="$(pwd)"

docker run --rm -it \
    -v "$PROJECT_DIR:$PROJECT_DIR" \
    -v ~/claude-sandbox:/home/ubuntu \
    -w "$PROJECT_DIR" \
    -e TZ=Asia/Tokyo \
    cr.quud.net/claude-sandbox:latest
