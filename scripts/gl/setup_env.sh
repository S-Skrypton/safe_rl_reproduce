#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_NAME="${ENV_NAME:-saferepro}"

cd "$REPO_ROOT"

echo "===== [1/8] Load conda ====="
source ~/miniconda3/etc/profile.d/conda.sh

echo "===== [2/8] Check whether env already exists ====="
if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "Conda env $ENV_NAME already exists, skip creation."
else
    echo "Creating conda env $ENV_NAME from conda-recipe.yaml"
    conda env create -n "$ENV_NAME" --file conda-recipe.yaml
fi

echo "===== [3/8] Activate env ====="
conda activate "$ENV_NAME"

echo "===== [4/8] Patch version metadata if needed ====="
python - <<'PY'
from pathlib import Path
import re
import sys

candidates = [
    Path("version.py"),
    Path("omnisafe/version.py"),
]

patched = False
found = False

for p in candidates:
    if not p.exists():
        continue
    found = True
    text = p.read_text()

    has_release = "__release__" in text
    has_version = "__version__" in text

    if has_release:
        print(f"{p}: already has __release__")
        continue

    if has_version:
        text = text.rstrip() + "\n__release__ = __version__\n"
        p.write_text(text)
        print(f"{p}: appended __release__ = __version__")
        patched = True
        continue

    m = re.search(r"version\s*=\s*['\"]([^'\"]+)['\"]", text)
    if m:
        v = m.group(1)
        text = text.rstrip() + f"\n__version__ = '{v}'\n__release__ = __version__\n"
        p.write_text(text)
        print(f"{p}: created __version__ and __release__ from version={v}")
        patched = True
        continue

    print(f"{p}: found but could not infer version fields", file=sys.stderr)

if not found:
    print("No version.py found in repo root or omnisafe/", file=sys.stderr)
    sys.exit(1)
PY

echo "===== [5/8] Upgrade build tools ====="
pip install -U pip setuptools wheel

echo "===== [6/8] Install OmniSafe in editable mode ====="
pip install -e . --no-build-isolation

echo "===== [7/8] Install Safety-Gymnasium ====="
pip install -U safety-gymnasium

echo "===== [8/8] Smoke import test ====="
python - <<'PY'
import omnisafe
print("omnisafe import ok")
import safety_gymnasium
print("safety_gymnasium import ok")
PY

echo "===== Setup finished successfully ====="
echo "Repo root : $REPO_ROOT"
echo "Env name  : $ENV_NAME"