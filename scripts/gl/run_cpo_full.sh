#!/bin/bash
#SBATCH --job-name=smoke10k
#SBATCH --account=eecs542w26s001_class
#SBATCH --partition=gpu_mig40,gpu,spgpu
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --output=logs/%x-%j.out

set -e
source ~/miniconda3/etc/profile.d/conda.sh
conda activate saferepro

cd ~/eecs567/omnisafe
mkdir -p logs

ENV_ID=SafetyPointGoal1-v0
SEED=0

omnisafe train \
  --algo CPO \
  --env-id SafetyPointGoal1-v0 \
  --total-steps 1024000 \
  --vector-env-nums 1 \
  --parallel 1 \
  --device cuda:0 \
  --torch-threads 8 \
  --custom-cfgs algo_cfgs:steps_per_epoch \
  --custom-cfgs 2048