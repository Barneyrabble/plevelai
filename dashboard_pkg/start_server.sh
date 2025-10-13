#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export PYTHONPATH="${PYTHONPATH:-}:${PWD}:/mnt/nvme/yolo"
python -m dashboard_pkg.run "$@"
