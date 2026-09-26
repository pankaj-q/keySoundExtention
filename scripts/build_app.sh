#!/bin/bash
#
# Builds keySoundExtension and installs it to /Applications with a
# STABLE code signature so the macOS Accessibility (TCC) grant survives
# every rebuild.
#
# The signature uses a fixed identifier + identifier-based designated
# requirement (no cdhash), so re-granting Accessibility after a rebuild
# is NOT needed. Only the very first install requires the manual grant:
#   System Settings -> Privacy & Security -> Accessibility -> add this app
#
set -euo pipefail

BUNDLE_ID="com.pankaj.keysoundextension"
APP_NAME="keySoundExtension"
APP_DIR="/Applications/${APP_NAME}.app"
CONFIG="release"

cd "$(dirname "$0")/.."

echo "==> swift build -c ${CONFIG}"
swift build -c "${CONFIG}"

BIN=".build/arm64-apple-macosx/${CONFIG}/${APP_NAME}"
RES_BUNDLE=".build/arm64-apple-macosx/${CONFIG}/${APP_NAME}_keySoundExtension.bundle"

[[ -x "$BIN" ]] || { echo "ERROR: binary not found at $BIN" >&2; exit 1; }
[[ -d "$RES_BUNDLE" ]] || { echo "ERROR: resource bundle not found at $RES_BUNDLE" >&2; exit 1; }

echo "==> Killing any running instance"
pkill -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
sleep 1

echo "==> Rebuilding clean app bundle at ${APP_DIR}"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN" "$APP_DIR/Contents/MacOS/${APP_NAME}"
cp -R "$RES_BUNDLE" "$APP_DIR/Contents/Resources/"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>keySound</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Validating Info.plist"
plutil -lint "$APP_DIR/Contents/Info.plist"

echo "==> Signing with stable identity '${BUNDLE_ID}'"
codesign --force --sign - \
    --identifier "$BUNDLE_ID" \
    "--requirements==designated => identifier \"${BUNDLE_ID}\"" \
    "$APP_DIR"

echo "==> Verifying signature"
codesign --verify --strict "$APP_DIR"
codesign -dr - "$APP_DIR/Contents/MacOS/${APP_NAME}"

echo "==> Launching app"
open "$APP_DIR"

echo ""
echo "Done. If this is the FIRST install, grant Accessibility once:"
echo "  System Settings -> Privacy & Security -> Accessibility"
echo "  Remove any old 'keySound' entries, then add: ${APP_DIR}"
echo "Future rebuilds via this script will NOT need re-granting."
