#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${1:-"$ROOT_DIR/root/Library/Input Methods/Yahoo! KeyKey.app"}"

echo "Bundle: $APP_PATH"
echo

find "$APP_PATH" -type f -perm -111 -print | while IFS= read -r file; do
  if /usr/bin/file "$file" | /usr/bin/grep -q "Mach-O"; then
    echo "== $file"
    /usr/bin/file "$file"
    echo
  fi
done

if /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH" >/tmp/keykey-codesign-audit.log 2>&1; then
  echo "codesign: OK"
else
  echo "codesign: failed"
  cat /tmp/keykey-codesign-audit.log
fi
