#!/bin/bash


cd /home/yang1641/PINNACLE
module load conda/2024.09
conda activate pinnacle

# Define model save directory
nepochs=${1} # number of epochs in one job - try 50
MAX_EPOCHS=${2} # 250
SAVE_PREFIX="/scratch/gilbreth/yang1641/exome/results/pinnacle/reproduce/epoch"${MAX_EPOCHS}
output_filename=try1
mkdir -p ${SAVE_PREFIX}


# input data dir
input_dir=/scratch/gilbreth/yang1641/exome/data/PINNACLE


# Check last epoch completed from logs
LOG_FILE=${SAVE_PREFIX}/${output_filename}_gnn_train.log

# 1) Figure out how many epochs are already done
EPOCHS_DONE=$(grep -oP "Epoch:\s*\K\d+" "$LOG_FILE" 2>/dev/null | tail -n 1 | sed 's/^0*//')
EPOCHS_DONE=${EPOCHS_DONE:-0}  # default 0 if not found
echo "EPOCHS_DONE: ${EPOCHS_DONE}"

# 2) Find the last saved model, to resume
LAST_MODEL=$(ls -t ${SAVE_PREFIX}/*_model_save.pth 2>/dev/null | head -n 1)

# 3) Calculate how many total "jobs" we need
#    (assuming MAX_EPOCHS is divisible by nepochs)
n_jobs=$(( MAX_EPOCHS / nepochs ))
# The current job index: how many "chunks" have finished + 1
job_i=$(( EPOCHS_DONE / nepochs + 1 ))


echo "Completed epochs so far: ${EPOCHS_DONE}"
echo "Launching job ${job_i} out of ${n_jobs} total (each job runs ${nepochs} epochs)."

# 4) Manage or retrieve the wandb run ID
WANDB_RUN_ID_FILE="${SAVE_PREFIX}/wandb_run_id.txt"


if [ ! -f "${WANDB_RUN_ID_FILE}" ]; then
    # We’re in the first job, so initialize a new wandb run
    echo "Initializing new W&B run..."
    # Use any unique string, e.g., from uuidgen
    # (You could also do something fancier in Python, but here’s a bash approach.)
    RUN_ID=$(uuidgen)
    echo "${RUN_ID}" > "${WANDB_RUN_ID_FILE}"
else
    # Subsequent jobs read the existing run ID
    RUN_ID=$(cat "${WANDB_RUN_ID_FILE}")
    echo "Reusing existing W&B run ID: ${RUN_ID}"
fi


# 5) Launch training for exactly 'nepochs' more epochs
if [[ -n "$LAST_MODEL" ]]; then
    echo "Resuming training from checkpoint: $LAST_MODEL"
    python pinnacle/train.py \
        --G_f "${input_dir}/networks/global_ppi_edgelist.txt" \
        --ppi_dir "${input_dir}/networks/ppi_edgelists/" \
        --mg_f "${input_dir}/networks/mg_edgelist.txt" \
        --batch_size=8 \
        --dropout=0.6 \
        --feat_mat=1024 \
        --hidden=64 \
        --lmbda=0.1 \
        --loader=graphsaint \
        --lr=0.01 \
        --lr_cent=0.1 \
        --n_heads=8 \
        --output=16 \
        --pc_att_channels=16 \
        --theta=0.3 \
        --wd=1e-05 \
        --epochs="${nepochs}" \
        --save_prefix "${SAVE_PREFIX}/${output_filename}" \
        --resume_run "${LAST_MODEL}" \
        --wandb_run_id "${RUN_ID}" \
        --completed_epochs "${EPOCHS_DONE}"
else
    echo "Starting fresh training run"
    python pinnacle/train.py \
        --G_f "${input_dir}/networks/global_ppi_edgelist.txt" \
        --ppi_dir "${input_dir}/networks/ppi_edgelists/" \
        --mg_f "${input_dir}/networks/mg_edgelist.txt" \
        --batch_size=8 \
        --dropout=0.6 \
        --feat_mat=1024 \
        --hidden=64 \
        --lmbda=0.1 \
        --loader=graphsaint \
        --lr=0.01 \
        --lr_cent=0.1 \
        --n_heads=8 \
        --output=16 \
        --pc_att_channels=16 \
        --theta=0.3 \
        --wd=1e-05 \
        --epochs="${nepochs}" \
        --save_prefix "${SAVE_PREFIX}/${output_filename}" \
        --wandb_run_id "${RUN_ID}" \
        --completed_epochs 0
fi

# 6) Check if we still have more chunks (jobs) to run
if [ "$EPOCHS_DONE" -lt "$MAX_EPOCHS" ]; then
    if [ "$job_i" -lt "$n_jobs" ]; then
        echo "Resubmitting job for next chunk..."
        cd /scratch/gilbreth/yang1641/exome/logs # go back to the log directory
        sbatch -N 1 --gres=gpu:2 --job-name=pinnacle_train --mem 40g -t 4:00:00 --mail-type=end,fail --mail-user=yang1641@purdue.edu -A standby "$0" "${nepochs}" "${MAX_EPOCHS}"
    else
        echo "We have reached ${job_i} jobs (i.e., ${EPOCHS_DONE} epochs). Training complete!"
    fi
else
    echo "Training complete!"
fi




