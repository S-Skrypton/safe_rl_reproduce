#!/bin/bash
set -e

source ~/miniconda3/etc/profile.d/conda.sh
conda activate saferepro

ROOT=~/eecs567/omnisafe/examples/benchmarks/exp-x/Benchmark_Safety_Velocity2.4
cd ~/eecs567/omnisafe/examples

FOCOPS_DIR=$(find "$ROOT" -type d -name 'FOCOPS-{SafetyHopperVelocity-v1}' | head -n 1)
CPO_DIR=$(find "$ROOT" -type d -name 'CPO-{SafetyHopperVelocity-v1}' | head -n 1)
PPOLAG_DIR=$(find "$ROOT" -type d -name 'PPOLag-{SafetyHopperVelocity-v1}' | head -n 1)

python -c "import sys, torch; print(sys.executable); print(torch.__file__)"

python plot.py \
  --logdir "$FOCOPS_DIR" "$CPO_DIR" "$PPOLAG_DIR" \
  --legend FOCOPS CPO PPOLag \
  --xaxis Steps \
  --value Rewards