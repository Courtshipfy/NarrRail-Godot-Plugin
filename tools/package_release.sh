#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$DIST_DIR/narrrail-godot-plugin-v$VERSION"
ZIP_PATH="$DIST_DIR/narrrail-godot-plugin-v$VERSION.zip"

cd "$ROOT_DIR"

if [[ ! -f "narrrail/plugin.cfg" ]]; then
  echo "Missing narrrail/plugin.cfg; run this script from the repository checkout." >&2
  exit 1
fi

rm -rf "$STAGE_DIR" "$ZIP_PATH"
mkdir -p "$STAGE_DIR"

cp -R "narrrail" "$STAGE_DIR/narrrail"
cp "README.md" "$STAGE_DIR/README.md"
cp "LICENSE" "$STAGE_DIR/LICENSE"
cp "CHANGELOG.md" "$STAGE_DIR/CHANGELOG.md"
cp "RELEASE_NOTES_v$VERSION.md" "$STAGE_DIR/RELEASE_NOTES.md"

find "$STAGE_DIR" -name ".DS_Store" -delete
find "$STAGE_DIR" -name ".godot" -type d -prune -exec rm -rf {} +
find "$STAGE_DIR" -name ".import" -type d -prune -exec rm -rf {} +

mkdir -p "$DIST_DIR"
(
  cd "$DIST_DIR"
  zip -qr "$(basename "$ZIP_PATH")" "$(basename "$STAGE_DIR")"
)

echo "Wrote $ZIP_PATH"
