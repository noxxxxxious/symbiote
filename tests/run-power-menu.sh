#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d /tmp/faishell-power-test.XXXXXX)"
trap 'rm -rf -- "$check_dir"' EXIT
cp -r -- "$repo_dir/components" "$check_dir/components"
cp -- "$repo_dir/tests/power-menu.qml" "$check_dir/shell.qml"
mkdir -m 700 "$check_dir/runtime"
test_status=0
XDG_RUNTIME_DIR="$check_dir/runtime" QT_QPA_PLATFORM=offscreen timeout 15s quickshell -p "$check_dir" --no-color > "$check_dir/test.log" 2>&1 || test_status=$?
cat "$check_dir/test.log"
if [[ "$test_status" -ne 0 ]] || ! grep -q 'PASS.*PowerMenu::test_gesture_and_menu' "$check_dir/test.log" || grep -q 'FAIL!' "$check_dir/test.log"; then
    exit 1
fi
