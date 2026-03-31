#!/bin/bash
#SBATCH --job-name=benchmark
#SBATCH --account=YOURACCOUNT
#SBATCH --partition=gpu_mig40,gpu,spgpu
#SBATCH --gpus=1
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x-%j.out

set -e
source ~/miniconda3/etc/profile.d/conda.sh
conda activate saferepro

cd ~/eecs567/omnisafe
mkdir -p logs

python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"

cd examples/benchmarks
python run_experiment_grid.py