#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SRC="$ROOT_DIR/vast-llm"
UI_SRC="$ROOT_DIR/vast-llm-launcher"
ENTRY_SRC="$ROOT_DIR/vast-llm-entry"
BENCH_SRC="$ROOT_DIR/vast-llm-bench"
DOCTOR_SRC="$ROOT_DIR/vast-llm-doctor"
DEST="${VAST_LLM_INSTALL_PATH:-/usr/local/bin/vast-llm}"
LIB_DIR="${VAST_LLM_LIB_DIR:-/usr/local/lib/vast-llm}"
CORE_DEST="$LIB_DIR/vast-llm-core"
UI_DEST="$LIB_DIR/vast-llm-ui"
BENCH_DEST="$LIB_DIR/vast-llm-bench"
DOCTOR_DEST="$LIB_DIR/vast-llm-doctor"

[[ -f "$CORE_SRC" ]] || { echo "ERROR: $CORE_SRC not found" >&2; exit 1; }
[[ -f "$UI_SRC" ]] || { echo "ERROR: $UI_SRC not found" >&2; exit 1; }
[[ -f "$ENTRY_SRC" ]] || { echo "ERROR: $ENTRY_SRC not found" >&2; exit 1; }
[[ -f "$BENCH_SRC" ]] || { echo "ERROR: $BENCH_SRC not found" >&2; exit 1; }
[[ -f "$DOCTOR_SRC" ]] || { echo "ERROR: $DOCTOR_SRC not found" >&2; exit 1; }

mkdir -p "$LIB_DIR" "$(dirname "$DEST")"
install -m 0755 "$CORE_SRC" "$CORE_DEST"
install -m 0755 "$UI_SRC" "$UI_DEST"
install -m 0755 "$BENCH_SRC" "$BENCH_DEST"
install -m 0755 "$DOCTOR_SRC" "$DOCTOR_DEST"
install -m 0755 "$ENTRY_SRC" "$DEST"

mkdir -p /data/vast-llm/profiles /data/vast-llm/logs /data/vast-llm/pids /data/vast-llm/benchmarks /data/vast-llm/runtime /data/models /data/huggingface

echo "Installed Vast LLM Manager:"
echo "  launcher:  $DEST"
echo "  core:      $CORE_DEST"
echo "  tuner UI:  $UI_DEST"
echo "  benchmark: $BENCH_DEST"
echo "  doctor:    $DOCTOR_DEST"
echo
echo "Run:"
echo "  vast-llm"
echo "  vast-llm benchmarks"
echo "  vast-llm bench-suite default quick"
echo "  vast-llm doctor"
echo "  vast-llm doctor --fix"
echo "  vast-llm wizard default"
echo
echo "Splash controls:"
echo "  VAST_LLM_NO_SPLASH=1 vast-llm       # disable splash"
echo "  NO_COLOR=1 vast-llm                  # monochrome splash"
echo
echo "Optional for gated/private Hugging Face repos:"
echo '  export HF_TOKEN="hf_..."'
