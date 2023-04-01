P_PER_NODE=$2
# # this should be same as ntasks-per-node/gpu_num

# ### init virtual environment if needed
source /gpfs/u/home/AICD/AICDzich/barn/miniconda3/etc/profile.d/conda.sh
conda activate VLC2

echo "P_PER_NODE"$P_PER_NODE
echo "SLURM_JOB_NUM_NODES"$SLURM_JOB_NUM_NODES
echo "SLURM_NODELIST"$SLURM_NODELIST

### the command to run
cd /gpfs/u/home/AICD/AICDzich/barn/code/MTMoe/

NODE_RANK=${SLURM_PROCID}
ip2=dcs${SLURM_NODELIST:3:3}
NODE_LENGTH=${#SLURM_NODELIST}
if [[ ${NODE_LENGTH} == 6  ]]; then
    ip2=dcs${SLURM_NODELIST:3:3}
else
    ip2=dcs${SLURM_NODELIST:4:3}
fi

export MASTER_ADDR=${ip2}
export MASTER_PORT="8000"
export NODE_RANK=${NODE_RANK}

echo "MASTER_ADDR"${MASTER_ADDR}
echo "MASTER_PORT"${MASTER_PORT}
echo "NODE_RANK"${NODE_RANK}
echo "EXP"$3
EXP=$3

python -m torch.distributed.launch \
    --master_addr ${ip2} \
    --node_rank ${NODE_RANK} \
    --nproc_per_node ${P_PER_NODE}  \
    --nnodes $SLURM_JOB_NUM_NODES    \
    main_pru_tuning.py \
        --batch_size 80 \
        --epochs 50 \
        --input_size 224 \
        --blr 6e-4 --weight_decay 0.05 \
        --warmup_epochs 4 \
        --times 1 \
        --cycle \
        --model mtvit_taskgate_small_att_mlp \
        --the_task class_scene \
        --copy fixnew_mtvit_taskgate_small_att_mlp_7 \
        --perc 0.99 \
        --drop_path 0.1 \
        --exp-name ${EXP} \

# python -m torch.distributed.launch --nnodes=1 --nproc_per_node=2 --master_port 44875 main_pru_tuning.py \
#         --batch_size 20 \
#         --epochs 100 \
#         --input_size 224 \
#         --blr 5e-4 --weight_decay 0.05 \
#         --warmup_epochs 10 \
#         --reprob 0.25 --mixup 0.8 --cutmix 1.0 \
#         --model mtvit_taskgate_small_att_mlp \
#         --drop_path 0.1 \
#         --times 1 \
#         --cycle \
#         --the_task class_scene \
#         --copy fixnew_mtvit_taskgate_small_att_mlp_7 \
#         --exp-name pruning_debug \

echo "FINISHED"
