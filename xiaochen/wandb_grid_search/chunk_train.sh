#!/bin/bash
# chunk_train.sh -- chunked training for a single hyperparameter combo

FEAT_MAT=$1          # e.g. 1024 or 2048
TOTAL_EPOCHS=$2      # e.g. 250
RUN_NAME=$3          # e.g. "feat1024_rep1"
CHUNK_SIZE=50        # how many epochs to run per chunk

module load conda/2024.09
conda activate pinnacle

SAVE_PREFIX="/scratch/.../$RUN_NAME"
LOG_FILE="${SAVE_PREFIX}/${RUN_NAME}_gnn_train.log"
mkdir -p "${SAVE_PREFIX}"

# Determine how many epochs are done so far
EPOCHS_DONE=0
if [ -f "$LOG_FILE" ]; then
  EPOCHS_DONE=$(grep -oP "Epoch:\s*\K\d+" "$LOG_FILE" | tail -n 1 | sed 's/^0*//')
  EPOCHS_DONE=${EPOCHS_DONE:-0}
fi
echo "So far, EPOCHS_DONE=$EPOCHS_DONE"

REMAINING=$(( TOTAL_EPOCHS - EPOCHS_DONE ))
if [ $REMAINING -le 0 ]; then
  echo "Training is already complete for $RUN_NAME!"
  exit 0
fi

# Decide how many epochs to do in this chunk
if [ $REMAINING -lt $CHUNK_SIZE ]; then
  CHUNK_SIZE=$REMAINING
fi

# Possibly find last checkpoint
LAST_MODEL=$(ls -t ${SAVE_PREFIX}/*_model_save.pth 2>/dev/null | head -n 1)

# Keep a consistent W&B run ID for all chunks of this one run
WANDB_RUN_ID_FILE="${SAVE_PREFIX}/wandb_run_id.txt"
if [ ! -f "$WANDB_RUN_ID_FILE" ]; then
    RUN_ID=$(uuidgen)
    echo "$RUN_ID" > "$WANDB_RUN_ID_FILE"
else
    RUN_ID=$(cat "$WANDB_RUN_ID_FILE")
fi

echo "Running $CHUNK_SIZE epochs now..."
CMD="python pinnacle/train.py \
  --feat_mat=$FEAT_MAT \
  --epochs=$CHUNK_SIZE \
  --save_prefix=${SAVE_PREFIX}/${RUN_NAME} \
  --completed_epochs=$EPOCHS_DONE \
  --wandb_run_id=$RUN_ID \
  --wandb_project_name=pinnacle_sweep"
if [ -n "$LAST_MODEL" ]; then
  CMD+=" --resume_run $LAST_MODEL"
fi

echo "CMD: $CMD"
$CMD

# After finishing this chunk, see if we still have more to do
NEW_DONE=$(( EPOCHS_DONE + CHUNK_SIZE ))
if [ $NEW_DONE -lt $TOTAL_EPOCHS ]; then
  echo "Re-submitting for next chunk..."
  sbatch -N 1 --gres=gpu:2 --mem=30g -t 4:00:00 \
    --job-name="$RUN_NAME" \
    -A standby \
    $0 $FEAT_MAT $TOTAL_EPOCHS $RUN_NAME
else
  echo "All done for $RUN_NAME!"
fi
