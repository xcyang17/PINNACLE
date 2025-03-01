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
EPOCHS_DONE=$(grep -oP "Epoch:\s*\K\d+" "$LOG_FILE" | tail -n 1 | sed 's/^0*//')
EPOCHS_DONE=${EPOCHS_DONE:-0}  # Default to 0 if not found


# Find the last saved model in SAVE_PREFIX
LAST_MODEL=$(ls -t ${SAVE_PREFIX}/*_model_save.pth 2>/dev/null | head -n 1)

# If a previous model exists, resume training
if [[ -n "$LAST_MODEL" ]]; then
    echo "Resuming from last checkpoint: $LAST_MODEL"
    python pinnacle/train.py \
        --G_f ${input_dir}/networks/global_ppi_edgelist.txt \
        --ppi_dir ${input_dir}/networks/ppi_edgelists/ \
        --mg_f ${input_dir}/networks/mg_edgelist.txt \
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
        --epochs=${nepochs} \
        --save_prefix ${SAVE_PREFIX}/${output_filename} \
        --resume_run="$LAST_MODEL"
else
    echo "Starting fresh training run"
    python pinnacle/train.py \
        --G_f ${input_dir}/networks/global_ppi_edgelist.txt \
        --ppi_dir ${input_dir}/networks/ppi_edgelists/ \
        --mg_f ${input_dir}/networks/mg_edgelist.txt \
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
        --epochs=${nepochs} \
        --save_prefix ${SAVE_PREFIX}/${output_filename}
fi


if [[ "$EPOCHS_DONE" -lt "$MAX_EPOCHS" ]]; then
    echo "Resubmitting job for continuation..."
    sbatch $0  # Resubmit the script
else
    echo "Training complete!"
fi

