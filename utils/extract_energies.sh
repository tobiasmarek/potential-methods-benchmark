#!/usr/bin/env bash
set -euo pipefail

# --- Usage check ---
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 path/to/cuby.log" >&2
    exit 1
fi

LOG_FILE="$1"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "❌ Log file not found: $LOG_FILE" >&2
    exit 1
fi

# --- Output header ---
echo "# Interaction energies in kcal/mol"

# --- Extract energy table ---
awk '
/^===/ { block = (block + 1) % 2; next }
block && /^[0-9]/ {
    name = $2
    energy = $3
    total_width = 32
    printf "%-*s%*.3f\n", total_width - 8, name, 8, energy
}' "$LOG_FILE"

# --- Extract summary lines ---
awk '
/^range[[:space:]]/     {print}
/^min abs[[:space:]]/   {print}
/^max abs[[:space:]]/   {print}
/^RMSE\/\|avg\|[[:space:]]/ {print}
/^MUE\/\|avg\|[[:space:]]/  {print}
/^===/ {exit}
' "$LOG_FILE"
