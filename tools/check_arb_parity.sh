#!/usr/bin/env bash
# ARB 翻譯檔 key / placeholder 一致性檢查
set -euo pipefail
cd "$(dirname "$0")/.."
dart tools/check_arb_parity.dart
