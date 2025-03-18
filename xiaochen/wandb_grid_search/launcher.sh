#!/bin/bash

# file1.sh – This script enumerates (feat_mat values) x (replications)
#            and sbatch-es a chunk_train.sh job for each run.

# Hard-coded or read from args:
NUM_REPS=3
EPOCHS_PER_RUN=250   # total epochs for each run

# Hypers to try:
FEAT_MATS="1024 2048"

# For each combo:
for FM in $FEAT_MATS; do
  for ((rep=1; rep<=$NUM_REPS; rep++)); do
    echo "Submitting job for feat_mat=$FM replicate=$rep"
    # pass them to chunk_train.sh
    sbatch \
      -N 1 --gres=gpu:2 --mem=30g -t 4:00:00 \
      --job-name="pinnacle_fm${FM}_rep${rep}" \
      -A standby \
      chunk_train.sh $FM $EPOCHS_PER_RUN $rep
  done
done
