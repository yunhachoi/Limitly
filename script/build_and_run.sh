#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -m)" != "arm64" ]]; then
  print -u2 "Limitly is arm64-only. Build this project on an Apple Silicon Mac."
  exit 2
fi

BUILD_PATH="${LIMITLY_BUILD_PATH:-/private/tmp/limitly-build-arm64}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/limitly-clang-cache}"
SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-/private/tmp/limitly-swift-cache}"
SPM_CACHE_PATH="${LIMITLY_SPM_CACHE_PATH:-/private/tmp/limitly-spm-cache}"
SPM_CONFIG_PATH="${LIMITLY_SPM_CONFIG_PATH:-/private/tmp/limitly-spm-config}"
SPM_SECURITY_PATH="${LIMITLY_SPM_SECURITY_PATH:-/private/tmp/limitly-spm-security}"
export CLANG_MODULE_CACHE_PATH SWIFT_MODULECACHE_PATH
mkdir -p \
  "$CLANG_MODULE_CACHE_PATH" \
  "$SWIFT_MODULECACHE_PATH" \
  "$SPM_CACHE_PATH" \
  "$SPM_CONFIG_PATH" \
  "$SPM_SECURITY_PATH"

SPM_COMMON_ARGS=(
  --disable-sandbox
  --cache-path "$SPM_CACHE_PATH"
  --config-path "$SPM_CONFIG_PATH"
  --security-path "$SPM_SECURITY_PATH"
  --manifest-cache local
)

VERIFY_ONLY=0
for argument in "$@"; do
  case "$argument" in
    --verify) VERIFY_ONLY=1 ;;
    *) print -u2 "Unknown option: $argument"; exit 2 ;;
  esac
done

stop_running_limitly() {
  if /usr/bin/pgrep -x Limitly >/dev/null 2>&1; then
    /usr/bin/pkill -TERM -x Limitly >/dev/null 2>&1 || true
    sleep 1
    /usr/bin/pkill -KILL -x Limitly >/dev/null 2>&1 || true
  fi
}

stop_running_limitly

swift build "${SPM_COMMON_ARGS[@]}" --configuration debug --build-path "$BUILD_PATH"
BIN_PATH="$(swift build "${SPM_COMMON_ARGS[@]}" --configuration debug --build-path "$BUILD_PATH" --show-bin-path)"
BINARY="$BIN_PATH/Limitly"
if [[ ! -x "$BINARY" ]]; then
  print -u2 "Built executable not found: $BINARY"
  exit 1
fi

ICON_OUTPUT="$BUILD_PATH/icons"
"$ROOT/scripts/make-icons.sh" "$ICON_OUTPUT" >/dev/null

APP="$BUILD_PATH/Limitly.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/Limitly"
cp "$ROOT/Limitly-Info.plist" "$APP/Contents/Info.plist"
cp "$ICON_OUTPUT/LimitlyIcon.png" "$APP/Contents/Resources/LimitlyIcon.png"
cp "$ICON_OUTPUT/Limitly.icns" "$APP/Contents/Resources/Limitly.icns"
chmod +x "$APP/Contents/MacOS/Limitly"

print "Launching $APP"
if [[ "${LIMITLY_NO_LAUNCH:-0}" == "1" ]]; then
  print "LIMITLY_NO_LAUNCH=1; launch skipped"
else
  /usr/bin/open -n "$APP"
  if (( VERIFY_ONLY )); then
    for _ in {1..20}; do
      if /usr/bin/pgrep -x Limitly >/dev/null 2>&1; then
        print "Limitly process is running"
        exit 0
      fi
      sleep 0.25
    done
    print -u2 "Limitly process did not start"
    exit 1
  fi
fi
