#!/bin/bash
#SBATCH --job-name=safepg1
#SBATCH --account=eecs542w26s001_class
#SBATCH --partition=gpu_mig40,gpu,spgpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gpus=1
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x-%j.out

set -euo pipefail

# ===== user-configurable vars =====
ENV_NAME="${ENV_NAME:-saferepro}"
ALGO="${ALGO:-CPO}"              # CPO or FOCOPS
SEED="${SEED:-0}"
ENV_ID="${ENV_ID:-SafetyPointGoal1-v0}"
TOTAL_STEPS="${TOTAL_STEPS:-1000000}"
SMOKE_STEPS="${SMOKE_STEPS:-20000}"
STEPS_PER_EPOCH="${STEPS_PER_EPOCH:-20000}"
VECTOR_ENVS="${VECTOR_ENVS:-1}"
TORCH_THREADS="${TORCH_THREADS:-8}"
DEVICE="${DEVICE:-cpu}"
SMOOTH="${SMOOTH:-5}"

# repo root = clone 下来的 omnisafe 根目录
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 输出写到 scratch，避免污染 repo
SCRATCH_ROOT="${SCRATCH_ROOT:-/scratch/eecs542w26s001_class_root/eecs542w26s001_class/$USER}"
RUN_ROOT="${SCRATCH_ROOT}/safe_rl_runs/${ENV_ID}/${ALGO}/seed_${SEED}"
mkdir -p "$RUN_ROOT"
mkdir -p "$REPO_ROOT/logs"

echo "===== Job info ====="
echo "REPO_ROOT   = $REPO_ROOT"
echo "RUN_ROOT    = $RUN_ROOT"
echo "ALGO        = $ALGO"
echo "ENV_ID      = $ENV_ID"
echo "SEED        = $SEED"
echo "TOTAL_STEPS = $TOTAL_STEPS"

echo "===== Load conda ====="
source ~/miniconda3/etc/profile.d/conda.sh
conda activate "$ENV_NAME"

cd "$REPO_ROOT"

echo "===== Basic import + env name check ====="
python - <<PY
import omnisafe
print("omnisafe import ok")
print("algo =", "${ALGO}")
print("env  =", "${ENV_ID}")
PY

echo "===== Stage 1: tiny smoke training ====="
python examples/train_policy.py \
    --algo "${ALGO}" \
    --env-id "${ENV_ID}" \
    --parallel 1 \
    --total-steps "${SMOKE_STEPS}" \
    --device "${DEVICE}" \
    --vector-env-nums "${VECTOR_ENVS}" \
    --torch-threads "${TORCH_THREADS}" \
    --seed "${SEED}"

echo "===== Stage 2: full training ====="
python examples/train_policy.py \
    --algo "${ALGO}" \
    --env-id "${ENV_ID}" \
    --parallel 1 \
    --total-steps "${TOTAL_STEPS}" \
    --device "${DEVICE}" \
    --vector-env-nums "${VECTOR_ENVS}" \
    --torch-threads "${TORCH_THREADS}" \
    --seed "${SEED}"

echo "===== Stage 3: collect latest run dir ====="
LATEST_DIR=$(find "$REPO_ROOT/examples/runs" -maxdepth 1 -type d -name "${ALGO}-{${ENV_ID}}*" | sort | tail -n 1 || true)

if [ -z "${LATEST_DIR}" ]; then
    echo "Could not find training output under examples/runs"
    exit 1
fi

echo "LATEST_DIR = $LATEST_DIR"

echo "===== Copy run to scratch ====="
DEST_DIR="${RUN_ROOT}/$(basename "$LATEST_DIR")"
rm -rf "$DEST_DIR"
cp -r "$LATEST_DIR" "$DEST_DIR"

echo "===== Stage 4: OmniSafe built-in plotting ====="
python examples/plot.py --logdir "$DEST_DIR" --value Rewards --smooth "$SMOOTH"
python examples/plot.py --logdir "$DEST_DIR" --value Costs --smooth "$SMOOTH"

echo "===== Finished ====="
echo "Saved run at: $DEST_DIR"