#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
check_dir="$(mktemp -d /tmp/faishell-workspace-test.XXXXXX)"
trap 'rm -rf -- "$check_dir"' EXIT
cp -r -- "$repo_dir/components" "$check_dir/components"
cp -- "$repo_dir/tests/workspaces.qml" "$check_dir/shell.qml"
mkdir -m 700 "$check_dir/runtime"
mkdir "$check_dir/bin"
# Fixed plugin response: these checks never reach the real compositor.
cat > "$check_dir/bin/hyprctl" <<'MOCK'
#!/usr/bin/env bash
echo '[{"id":1,"name":"one","focused":false},{"id":2,"name":"work","focused":true}]'
MOCK
chmod +x "$check_dir/bin/hyprctl"
test_status=0
PATH="$check_dir/bin:$PATH" XDG_RUNTIME_DIR="$check_dir/runtime" QT_QPA_PLATFORM=offscreen timeout 15s quickshell -p "$check_dir" --no-color > "$check_dir/test.log" 2>&1 || test_status=$?
cat "$check_dir/test.log"
if [[ "$test_status" -ne 0 ]] || ! grep -q 'PASS Workspaces::check' "$check_dir/test.log" || grep -q 'FAIL!' "$check_dir/test.log"; then
    exit 1
fi
