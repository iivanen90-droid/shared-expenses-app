#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../packages/ui_kit"
fvm dart run build_runner build --force-jit
