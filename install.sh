#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SRC="$ROOT_DIR/vast-llm"
LAUNCHER_SRC="$ROOT_DIR/vast-llm-launcher"
DEST="${VAST_LLM_INSTALL_PATH:-/usr/local/bin/vast-llm}"
LIB_DIR="${VAST_LLM_LIB_DIR:-/usr/local/lib/vast-llm}"
CORE_DEST="$LIB_DIR/vast-llm-core"

[[ -f "$CORE_SRC" ]] || { echo "ERROR: $CORE_SRC not found" >&2; exit 1; }
[[ -f "$LAUNCHER_SRC" ]] || { echo "ERROR: $LAUNCHER_SRC not found" >&2; exit 1; }

mkdir -p "$LIB_DIR" "$(dirname "$DEST")"
install -m 0755 "$CORE_SRC" "$CORE_DEST"
install -m 0755 "$LAUNCHER_SRC" "$DEST"

mkdir -p /data/vast-llm/profiles /data/vast-llm/logs /data/vast-llm/pids /data/models /data/huggingface

echo "Installed Vast LLM Manager:"
echo "  launcher: $DEST"
echo "  core:     $CORE_DEST"
echo
echo "Run:"
echo "  vast-llm"
echo "  vast-llm doctor"
echo "  vast-llm wizard default"
echo
echo "Splash controls:"
echo "  VAST_LLM_NO_SPLASH=1 vast-llm       # disable splash"
echo "  NO_COLOR=1 vast-llm                  # monochrome splash"
echo
echo "Optional for gated/private Hugging Face repos:"
echo '  export HF_TOKEN="hf_..."'
