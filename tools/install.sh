#!/usr/bin/env bash
set -euo pipefail
cd /workspace/Roblox-Run-a-record-label
mkdir -p .tools build
npm --cache /tmp/record-label-npm-cache ci --ignore-scripts
python3 tools/install_rojo.py
npm test
.tools/rojo build default.project.json -o build/RecordLabel.rbxlx
