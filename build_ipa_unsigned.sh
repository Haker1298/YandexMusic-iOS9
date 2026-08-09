#!/bin/bash
# Build UNSIGNED .ipa from Theos project (for sideloading via Sideloadly/AltStore)
# Sideloadly/AltStore will re-sign with your Apple ID automatically
#
# Usage: ./build_ipa_unsigned.sh
# Requires: macOS, Theos, Xcode Command Line Tools

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_DIR/.theos/obj/debug"
APP_NAME="YandexMusic"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
OUTPUT_DIR="$PROJECT_DIR/build"
STAGING_DIR="/tmp/ym_ipa_staging"

echo "========================================"
echo " Yandex Music - IPA Builder"
echo "========================================"

# Step 1: Build
if [ "$1" != "--skip-build" ]; then
    echo ""
    echo "[1/4] Building $APP_NAME.app..."
    cd "$PROJECT_DIR"
    make clean 2>/dev/null || true
    make
fi

# Step 2: Verify
if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: $APP_BUNDLE not found!"
    echo "Build failed."
    exit 1
fi

# Step 3: Strip signatures (sideloading tool will re-sign)
echo ""
echo "[2/4] Preparing bundle..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/Payload"
cp -R "$APP_BUNDLE" "$STAGING_DIR/Payload/"

# Remove existing code signature so sideloading tool can re-sign cleanly
find "$STAGING_DIR/Payload/$APP_NAME.app" -name "_CodeSignature" -exec rm -rf {} + 2>/dev/null || true
find "$STAGING_DIR/Payload/$APP_NAME.app" -name "embedded.mobileprovision" -delete 2>/dev/null || true

# Step 4: Package as .ipa
echo ""
echo "[3/4] Packaging .ipa..."
mkdir -p "$OUTPUT_DIR"
cd "$STAGING_DIR"
zip -r -q "$OUTPUT_DIR/$APP_NAME.ipa" Payload/
rm -rf "$STAGING_DIR"

echo ""
echo "[4/4] Done!"
echo ""
echo "Output: $OUTPUT_DIR/$APP_NAME.ipa"
ls -lh "$OUTPUT_DIR/$APP_NAME.ipa"
echo ""
echo "--- Installation ---"
echo "1. Transfer .ipa to your computer"
echo "2. Open Sideloadly (sideloadly.io) or AltStore"
echo "3. Connect iPhone 4S via USB"
echo "4. Select the .ipa file"
echo "5. Enter your Apple ID (free account works)"
echo "6. Wait for installation"
echo ""
echo "Note: Free developer cert expires in 7 days."
echo "      Re-sideload to refresh. Or use a paid developer account."
