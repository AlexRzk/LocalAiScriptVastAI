#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT_DIR/vast-llm"
DEST="${VAST_LLM_INSTALL_PATH:-/usr/local/bin/vast-llm}"

[[ -f "$SRC" ]] || { echo "ERROR: $SRC not found" >&2; exit 1; }

chmod +x "$SRC"
mkdir -p "$(dirname "$DEST")"
ln -sf "$SRC" "$DEST"

mkdir -p /data/vast-llm/profiles /data/vast-llm/logs /data/vast-llm/pids /data/models /data/huggingface

echo "Installed: $DEST -> $SRC"
echo
echo "Run:"
echo "  vast-llm doctor"
echo "  vast-llm wizard default"
echo
echo "Optional for gated/private Hugging Face repos:"
echo '  export HF_TOKEN="hf_..."'
