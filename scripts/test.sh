#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "$(uname -m)" != "arm64" ]]; then
  print -u2 "Limitly tests must run on an Apple Silicon Mac."
  exit 2
fi

BUILD_PATH="${LIMITLY_TEST_BUILD_PATH:-/private/tmp/limitly-test-arm64}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/limitly-clang-cache}"
SWIFT_MODULECACHE_PATH="${SWIFT_MODULECACHE_PATH:-/private/tmp/limitly-swift-cache}"
SPM_CACHE_PATH="${LIMITLY_SPM_CACHE_PATH:-/private/tmp/limitly-spm-cache}"
SPM_CONFIG_PATH="${LIMITLY_SPM_CONFIG_PATH:-/private/tmp/limitly-spm-config}"
SPM_SECURITY_PATH="${LIMITLY_SPM_SECURITY_PATH:-/private/tmp/limitly-spm-security}"
CHECK_PATH="${LIMITLY_CHECK_PATH:-/private/tmp/limitly-core-checks}"
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

# XCTest is shipped with the full Xcode installation. Command Line Tools can
# compile the app but do not include the XCTest Swift module used by SwiftPM.
XCTEST_PROBE="$(mktemp -t limitly-xctest-probe).swift"
trap 'rm -f "$XCTEST_PROBE"' EXIT
cat >"$XCTEST_PROBE" <<'EOF'
import XCTest
EOF

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
HAS_XCTEST=0
if [[ -n "$SDK_PATH" ]] && swiftc \
  -sdk "$SDK_PATH" \
  -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  -typecheck "$XCTEST_PROBE" >/dev/null 2>&1; then
  HAS_XCTEST=1
fi

if (( HAS_XCTEST )); then
  print "XCTest module detected; running SwiftPM tests."
  swift test "${SPM_COMMON_ARGS[@]}" --build-path "$BUILD_PATH"
  exit 0
fi

print "XCTest module is unavailable in the active developer tools."
print "Running the equivalent Limitly core checks instead."
print "Install the full Xcode app and select it with:"
print "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"

if [[ -z "$SDK_PATH" ]]; then
  print -u2 "Could not locate the macOS SDK via xcrun."
  exit 1
fi

swiftc \
  -sdk "$SDK_PATH" \
  -module-cache-path "$CLANG_MODULE_CACHE_PATH" \
  "$ROOT/Sources/LimitlyCore/RateLimits.swift" \
  "$ROOT/Sources/LimitlyCore/CodexExecutableLocator.swift" \
  "$ROOT/Sources/LimitlyCore/JSONRPC.swift" \
  "$ROOT/Sources/LimitlyCore/MenuBarStatusFormatter.swift" \
  "$ROOT/Sources/LimitlyCore/DashboardDateFormatter.swift" \
  "$ROOT/Sources/LimitlyCore/MenuBarPopoverPolicy.swift" \
  "$ROOT/Sources/LimitlyCore/LimitlySettingsDefaults.swift" \
  "$ROOT/scripts/main.swift" \
  -o "$CHECK_PATH"
"$CHECK_PATH"
