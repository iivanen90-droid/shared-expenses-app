#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../packages/common"
fvm dart run easy_localization:generate -S lib/src/localization/langs -O lib/src/localization -f keys -o locale_keys.g.dart
