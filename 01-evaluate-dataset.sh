#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n DATASET -m METHOD1 [METHOD2 ...]"
  echo "Example: $0 -n PLA15 -m PM6-ML PM7-ML"
  exit 1
}

DATASET=""
METHODS=()

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--name)
      DATASET="$2"
      shift 2
      ;;
    -m|--methods)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        METHODS+=("$1")
        shift
      done
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$DATASET" || ${#METHODS[@]} -eq 0 ]]; then
  usage
fi

# --- Loop through each method ---
for METHOD in "${METHODS[@]}"; do
  echo "----------------------------------------"
  echo " Evaluating dataset: $DATASET with method: $METHOD"
  echo "----------------------------------------"

  METHOD_DIR="methods/$METHOD"
  TEMPLATE="$METHOD_DIR/template.yaml"
  MODEL_FILE="$METHOD_DIR/model_path.txt"

  if [[ ! -f "$TEMPLATE" || ! -f "$MODEL_FILE" ]]; then
    echo "❌ Missing files in $METHOD_DIR (need template.yaml and model)"
    exit 1
  fi

  export DATASET
  export MODEL_PATH
  MODEL_PATH=$(cat "$MODEL_FILE")

  # --- Extract conda environment name ---
  ENV_NAME=$(head -n 1 "$TEMPLATE" | awk '{print $4}')
  if [[ -z "$ENV_NAME" ]]; then
    echo "❌ Could not find environment name in first line of $TEMPLATE"
    exit 1
  fi

  echo "🔹 Activating environment: $ENV_NAME"

  # --- Activate environment ---
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate "$ENV_NAME"

  # --- Substitute placeholders ---
  TMP_YAML="tmp_${METHOD}.yaml"
  envsubst < "$TEMPLATE" > "$TMP_YAML"

  # --- Run cuby4 ---
  echo "Running Cuby4 in environment '$ENV_NAME'..."
  cuby4 "$TMP_YAML"

  # --- Cleanup ---
  rm "$TMP_YAML"
  conda deactivate
  unset DATASET MODEL_PATH
  echo "✅ Finished method: $METHOD"
  echo
done

echo "🎉 All methods complete for dataset: $DATASET"
