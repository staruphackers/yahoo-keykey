#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-run}"
BUILD_DIR="$ROOT_DIR/build"
STAGE_DIR="$BUILD_DIR/stage"
COMPONENT_PKG="$BUILD_DIR/YahooKeyKeyApp.pkg"
OUTPUT_PKG="$BUILD_DIR/YahooKeyKey-modern.pkg"
VERSION="${VERSION:-7.1.0}"

cd "$ROOT_DIR"
mkdir -p "$BUILD_DIR"

case "$MODE" in
  run|--verify|verify)
    ;;
  *)
    echo "usage: $0 [run|--verify]" >&2
    exit 2
    ;;
esac

./script/prepare_modern_stage.sh "$STAGE_DIR" >/dev/null

/usr/bin/pkgbuild \
  --root "$STAGE_DIR" \
  --identifier com.yahoo.keykey.installerpackage \
  --version "$VERSION" \
  --ownership recommended \
  --scripts "$ROOT_DIR/Scripts" \
  "$COMPONENT_PKG"

PRODUCTBUILD_ARGS=(
  --product "$ROOT_DIR/requirement.plist"
  --distribution "$ROOT_DIR/distribution.plist"
  --resources "$ROOT_DIR/Resources"
  --package-path "$BUILD_DIR"
)

if [[ -n "${INSTALLER_SIGN_IDENTITY:-}" ]]; then
  PRODUCTBUILD_ARGS=(--sign "$INSTALLER_SIGN_IDENTITY" "${PRODUCTBUILD_ARGS[@]}")
fi

/usr/bin/productbuild "${PRODUCTBUILD_ARGS[@]}" "$OUTPUT_PKG"
/usr/sbin/pkgutil --check-signature "$OUTPUT_PKG" || true

if [[ "$MODE" == "--verify" || "$MODE" == "verify" ]]; then
  ./script/audit_bundle.sh "$STAGE_DIR/Library/Input Methods/Yahoo! KeyKey.app"
  /usr/bin/xmllint --noout "$ROOT_DIR/distribution.plist"
  /usr/bin/plutil -lint "$ROOT_DIR/requirement.plist" "$STAGE_DIR/Library/Input Methods/Yahoo! KeyKey.app/Contents/Info.plist"
  /usr/sbin/spctl -a -vvv -t install "$OUTPUT_PKG" || true
fi

echo "Built $OUTPUT_PKG"
