#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${LIMITLY_VERSION:-1.0.0}"
BUILD_PATH="${LIMITLY_BUILD_PATH:-/private/tmp/limitly-build-arm64}"
VOLUME_NAME="${LIMITLY_VOLUME_NAME:-Limitly $VERSION-arm64}"
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

if [[ "$(uname -m)" != "arm64" ]]; then
  print -u2 "Limitly is arm64-only. Package this project on an Apple Silicon Mac."
  exit 2
fi

swift build "${SPM_COMMON_ARGS[@]}" --configuration release --build-path "$BUILD_PATH"
BIN_PATH="$(swift build "${SPM_COMMON_ARGS[@]}" --configuration release --build-path "$BUILD_PATH" --show-bin-path)"
BINARY="$BIN_PATH/Limitly"
[[ -x "$BINARY" ]] || { print -u2 "Built executable not found: $BINARY"; exit 1; }

ICON_OUTPUT="$BUILD_PATH/icons"
"$ROOT/scripts/make-icons.sh" "$ICON_OUTPUT" >/dev/null
ARROW_OUTPUT="$BUILD_PATH/dmg-arrow.png"
python3 "$ROOT/scripts/create-dmg-arrow.py" "$ARROW_OUTPUT" >/dev/null

STAGE="$BUILD_PATH/dmg-staging"
APP="$STAGE/Limitly.app"
DMG="$ROOT/Limitly-$VERSION.dmg"
RW_DMG="$BUILD_PATH/Limitly-$VERSION-rw.dmg"
ATTACH_PLIST="$BUILD_PATH/Limitly-$VERSION-attach.plist"
MOUNT_POINT=""

cleanup() {
  if [[ -n "$MOUNT_POINT" && -d "$MOUNT_POINT" ]]; then
    /usr/bin/hdiutil detach "$MOUNT_POINT" -force >/dev/null 2>&1 || true
  fi
  rm -f "$RW_DMG" "$ATTACH_PLIST"
}
trap cleanup EXIT

# Keep an existing release image until the replacement has been converted and
# verified. A failed hdiutil/Finder step should not destroy the last usable DMG.
rm -rf "$STAGE"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$STAGE/.background"
cp "$BINARY" "$APP/Contents/MacOS/Limitly"
cp "$ROOT/Limitly-Info.plist" "$APP/Contents/Info.plist"
cp "$ICON_OUTPUT/LimitlyIcon.png" "$APP/Contents/Resources/LimitlyIcon.png"
cp "$ICON_OUTPUT/Limitly.icns" "$APP/Contents/Resources/Limitly.icns"
chmod +x "$APP/Contents/MacOS/Limitly"

ln -s /Applications "$STAGE/Applications"
cp "$ICON_OUTPUT/Limitly.icns" "$STAGE/.VolumeIcon.icns"
chflags hidden "$STAGE/.VolumeIcon.icns" 2>/dev/null || true
cp "$ARROW_OUTPUT" "$STAGE/.background/Limitly-DMGArrow.png"
chflags hidden "$STAGE/.background" 2>/dev/null || true

if [[ -n "${DEVELOPER_IDENTITY:-}" ]]; then
  codesign --force --deep --options runtime --sign "$DEVELOPER_IDENTITY" "$APP"
else
  codesign --force --deep --sign - "$APP"
fi

"$ROOT/scripts/verify.sh" "$APP"
DEVELOPMENT_APP="$ROOT/Limitly.app"
rm -rf "$DEVELOPMENT_APP"
cp -R "$APP" "$DEVELOPMENT_APP"

# Create a writable image first so Finder can persist the installer layout in
# its .DS_Store. The final release image remains compressed and read-only.
/usr/bin/hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -fs HFS+ \
  -ov \
  -format UDRW \
  "$RW_DMG" >/dev/null

# A previously opened Limitly DMG can make Finder resolve the wrong disk by
# volume name. Close any matching development mounts before configuring the
# freshly created image.
setopt null_glob
for existingVolume in "/Volumes/$VOLUME_NAME"*; do
  if [[ -d "$existingVolume" ]]; then
    /usr/bin/hdiutil detach "$existingVolume" -force >/dev/null 2>&1 || true
  fi
done

/usr/bin/hdiutil attach \
  -nobrowse \
  -readwrite \
  -plist \
  "$RW_DMG" > "$ATTACH_PLIST"

MOUNT_POINT="$(/usr/libexec/PlistBuddy -c 'Print :system-entities:1:mount-point' "$ATTACH_PLIST" 2>/dev/null || true)"
if [[ -z "$MOUNT_POINT" ]]; then
  MOUNT_POINT="$(/usr/bin/plutil -p "$ATTACH_PLIST" | /usr/bin/sed -n 's/.*"mount-point" => "\(.*\)"/\1/p' | /usr/bin/head -1)"
fi
if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  print -u2 "Unable to determine the mounted DMG path"
  exit 1
fi

/usr/bin/osascript \
  "$ROOT/scripts/configure-dmg-layout.applescript" \
  "$VOLUME_NAME" \
  "$MOUNT_POINT/.background/Limitly-DMGArrow.png"
/usr/bin/hdiutil detach "$MOUNT_POINT" >/dev/null
MOUNT_POINT=""

/usr/bin/hdiutil convert \
  "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  -o "$DMG" >/dev/null
/usr/bin/hdiutil verify "$DMG"
print "Created $DMG"
