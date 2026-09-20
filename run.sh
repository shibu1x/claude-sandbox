#!/bin/sh
set -eu

if [ $# -lt 1 ]; then
    echo "Usage: $0 <workspace_dir>" >&2
    exit 1
fi

WORKSPACE_DIR="$1"

docker run --rm -it \
    -v "$(cd "$WORKSPACE_DIR" && pwd):/workspace" \
    -v ~/claude-sandbox:/home/ubuntu \
    -w /workspace \
    -e TZ=Asia/Tokyo \
    cr.quud.net/claude-sandbox:latest
