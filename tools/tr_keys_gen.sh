#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../packages/common"
fvm_command=fvm
if ! command -v "$fvm_command" >/dev/null 2>&1 && command -v fvm.bat >/dev/null 2>&1; then
  fvm_command=fvm.bat
fi
"$fvm_command" dart run easy_localization:generate -S lib/src/localization/langs -s en.json -O lib/src/localization -f keys -o locale_keys.g.dart
"$fvm_command" dart format lib/src/localization/locale_keys.g.dart
