#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE_DIR="${1:-"$ROOT_DIR/build/stage"}"
APP_PATH="$STAGE_DIR/Library/Input Methods/Yahoo! KeyKey.app"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

copy_root() {
  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  /usr/bin/ditto "$ROOT_DIR/root" "$STAGE_DIR"
}

thin_to_x86_64() {
  local binary="$1"

  if [[ ! -f "$binary" ]]; then
    echo "missing binary: $binary" >&2
    return 1
  fi

  if /usr/bin/lipo "$binary" -verify_arch x86_64 >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/keykey-lipo.XXXXXX")"
    /usr/bin/lipo "$binary" -thin x86_64 -output "$tmp"
    /bin/mv "$tmp" "$binary"
    /bin/chmod 755 "$binary"
  else
    echo "binary does not contain x86_64: $binary" >&2
    return 1
  fi
}

remove_unusable_helpers() {
  # These helper apps are 32-bit-only in the archived Yahoo! KeyKey bundle.
  # Removing them avoids post-install crashes and invalid nested-code signatures
  # on modern macOS while preserving the main input method and Preferences app.
  rm -rf \
    "$APP_PATH/Contents/SharedSupport/DownloadUpdate.app" \
    "$APP_PATH/Contents/SharedSupport/InstallerHelp.app" \
    "$APP_PATH/Contents/SharedSupport/PhraseEditor.app"
}

modernize_plists() {
  local main_plist="$APP_PATH/Contents/Info.plist"
  "$PLIST_BUDDY" -c "Set :LSMinimumSystemVersion 10.13.0" "$main_plist"
  "$PLIST_BUDDY" -c "Delete :LSMinimumSystemVersionByArchitecture" "$main_plist" >/dev/null 2>&1 || true
  "$PLIST_BUDDY" -c "Set :CFBundleShortVersionString 1.1.2535-modern.1" "$main_plist" >/dev/null 2>&1 || \
    "$PLIST_BUDDY" -c "Add :CFBundleShortVersionString string 1.1.2535-modern.1" "$main_plist"
}

sign_bundle() {
  local identity="${APP_SIGN_IDENTITY:--}"

  /usr/bin/codesign --force --deep --sign "$identity" "$APP_PATH"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_PATH"
}

copy_root
remove_unusable_helpers
thin_to_x86_64 "$APP_PATH/Contents/MacOS/Yahoo! KeyKey"
thin_to_x86_64 "$APP_PATH/Contents/Frameworks/OpenVanilla.framework/Versions/A/OpenVanilla"
thin_to_x86_64 "$APP_PATH/Contents/Frameworks/LFExtensions.framework/Versions/A/LFExtensions"
modernize_plists
sign_bundle

echo "$STAGE_DIR"
