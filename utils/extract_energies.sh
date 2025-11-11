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
block && /^[[:space:]]*[0-9]/ {
    # find first numeric field (supports 1.23, -4.5, 6e-3, -7.8E+2, etc.)
    firstnum = 0
    for (i = 2; i <= NF; i++) {
        if ($i ~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) { firstnum = i; break }
    }
    if (!firstnum) next  # no numeric found on this line

    # name is everything between the index ($1) and the first numeric
    name = $2
    for (j = 3; j < firstnum; j++) name = name " " $j

    energy = $firstnum
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
