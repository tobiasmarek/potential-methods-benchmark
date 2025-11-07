#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 -n DATASET -m METHOD1 [METHOD2 ...]"
  echo "Example: $0 -n PLA15 -m PM6-ML UMA-S"
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
  echo "============================================================"
  echo " Evaluating dataset: $DATASET with method: $METHOD"
  echo "------------------------------------------------------------"

  METHOD_DIR="methods/$METHOD"
  TEMPLATE="$METHOD_DIR/template.yaml"
  MODEL_FILE="$METHOD_DIR/model_path.txt"

  RESULT_DIR="results/$METHOD"
  mkdir -p "$RESULT_DIR"
  LOG_FILE="$RESULT_DIR/cuby.log"

  {
    # Temporarily disable exit-on-error to handle failures manually
    set +e

    # --- template.yaml is always required ---
    if [[ ! -f "$TEMPLATE" ]]; then
      echo "🔺 Missing template.yaml in $METHOD_DIR"
      exit 1
    fi

    # --- model_path.txt is optional ---
    if [[ -f "$MODEL_FILE" ]]; then
      MODEL_PATH=$(cat "$MODEL_FILE")
      export MODEL_PATH
      echo "🔹 Using model: $MODEL_PATH"
    else
      echo "🔹 Model path not set"
    fi

    export DATASET

    ENV_NAME=$(head -n 1 "$TEMPLATE" | awk '{print $4}')
    if [[ -z "$ENV_NAME" ]]; then
      echo "🔺 Could not find environment name in first line of $TEMPLATE"
      exit 1
    fi

    echo "🔹 Activating environment: $ENV_NAME"
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate "$ENV_NAME"

    TMP_YAML="tmp_${METHOD}.yaml"
    envsubst < "$TEMPLATE" > "$TMP_YAML"

    echo "🔹 Logging output to $LOG_FILE"
    echo "Running Cuby4 in environment '$ENV_NAME'..."

    cuby4 "$TMP_YAML" > "$LOG_FILE" 2>&1
    STATUS=$?

    if [[ $STATUS -ne 0 ]]; then
      echo "Cuby4 failed for $METHOD (exit code $STATUS)" >> "$LOG_FILE"
      echo "🔺 Failed method: $METHOD — log saved to $LOG_FILE"
      conda deactivate
      unset MODEL_PATH
      rm -f "$TMP_YAML"
      continue
    fi

    echo "🔹 Extracting energies..."
    ./utils/extract_energies.sh "$LOG_FILE" > "$RESULT_DIR/table.txt"

    rm "$TMP_YAML"
    conda deactivate
    unset MODEL_PATH

    echo "✅ Finished method: $METHOD — log saved to $LOG_FILE"
    echo

    # Re-enable exit-on-error
    set -e
  } || {
    echo "❌ Failed method: $METHOD — log saved to $LOG_FILE"
    echo
    continue
  }
done

echo "============================================================"
echo " ⏵ Pipeline finished for dataset: $DATASET"

unset DATASET