#!/bin/bash


cd /home/yang1641/PINNACLE
module load anaconda
conda activate pinnacle

output_dir=/scratch/bell/yang1641/exome/results/pinnacle/reproduce/epoch10
output_filename=try1
mkdir -p ${output_dir}

# TODO: change epochs back to 250 later
python /home/yang1641/PINNACLE/pinnacle/train.py \
        --G_f /scratch/bell/yang1641/exome/data/PINNACLE/networks/global_ppi_edgelist.txt \
        --ppi_dir /scratch/bell/yang1641/exome/data/PINNACLE/networks/ppi_edgelists/ \
        --mg_f /scratch/bell/yang1641/exome/data/PINNACLE/networks/mg_edgelist.txt \
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
        --epochs=10 \
        --save_prefix ${output_dir}/${output_filename}
