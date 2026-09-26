#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-/private/tmp/limitly-build-arm64/Limitly.app}"
EXECUTABLE="$APP/Contents/MacOS/Limitly"

if [[ "$(uname -m)" != "arm64" ]]; then
  print -u2 "Verification must run on an Apple Silicon Mac."
  exit 2
fi
[[ -d "$APP" ]] || { print -u2 "Missing app bundle: $APP"; exit 1; }
[[ -x "$EXECUTABLE" ]] || { print -u2 "Missing executable: $EXECUTABLE"; exit 1; }

print "Bundle: $APP"
/usr/bin/plutil -p "$APP/Contents/Info.plist"

# Keep the bundle discoverable by Finder Applications and Launchpad. The app
# switches to the accessory activation policy at runtime, so the bundle must
# still declare a normal, foreground-capable application.
PACKAGE_TYPE="$(/usr/bin/plutil -extract CFBundlePackageType raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
if [[ "$PACKAGE_TYPE" != "APPL" ]]; then
  print -u2 "The bundle is not a regular application (CFBundlePackageType=$PACKAGE_TYPE)."
  exit 1
fi
LS_UI_ELEMENT="$(/usr/bin/plutil -extract LSUIElement raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
if [[ "$LS_UI_ELEMENT" != "false" ]]; then
  print -u2 "The bundle must explicitly declare LSUIElement=false for Finder Applications/Launchpad visibility (found: $LS_UI_ELEMENT)."
  exit 1
fi
LS_BACKGROUND_ONLY="$(/usr/bin/plutil -extract LSBackgroundOnly raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
if [[ "$LS_BACKGROUND_ONLY" != "false" ]]; then
  print -u2 "The bundle must explicitly declare LSBackgroundOnly=false for Finder Applications/Launchpad visibility (found: $LS_BACKGROUND_ONLY)."
  exit 1
fi
ICON_FILE="$(/usr/bin/plutil -extract CFBundleIconFile raw -o - "$APP/Contents/Info.plist" 2>/dev/null || true)"
if [[ -z "$ICON_FILE" || ! -f "$APP/Contents/Resources/$ICON_FILE" ]]; then
  print -u2 "The Launchpad icon resource is missing: $ICON_FILE"
  exit 1
fi
print "LaunchServices visibility: regular application (CFBundlePackageType=APPL, LSUIElement=false, LSBackgroundOnly=false, icon=$ICON_FILE)"

print "Executable architecture:"
/usr/bin/file "$EXECUTABLE"

FILE_OUTPUT="$(/usr/bin/file "$EXECUTABLE")"
if [[ "$FILE_OUTPUT" != *"arm64"* || "$FILE_OUTPUT" == *"x86_64"* ]]; then
  print -u2 "The executable is not arm64-only: $FILE_OUTPUT"
  exit 1
fi

if /usr/bin/codesign --verify --deep --strict "$APP" 2>/dev/null; then
  print "Code signature: valid"
else
  print "Code signature: not valid or unsigned (allowed for debug staging)"
fi

print "App bundle verification passed."
