#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-/private/tmp/limitly-build-arm64/icons}"
SOURCE_ICO="$ROOT/Limitly.ico"

if [[ ! -f "$SOURCE_ICO" ]]; then
  print -u2 "Missing icon source: $SOURCE_ICO"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
PNG="$OUTPUT_DIR/LimitlyIcon.png"
ICNS="$OUTPUT_DIR/Limitly.icns"

sips -s format png "$SOURCE_ICO" --out "$PNG" >/dev/null
sips -s format icns "$SOURCE_ICO" --out "$ICNS" >/dev/null
print "Generated $PNG"
print "Generated $ICNS"
