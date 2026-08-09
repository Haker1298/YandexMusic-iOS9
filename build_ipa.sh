#!/bin/bash
# Build .ipa from Theos project
# Run on macOS with Theos installed

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.theos/obj/debug"
APP_NAME="YandexMusic"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
OUTPUT_DIR="$PROJECT_DIR/build"
IPA_NAME="$APP_NAME.ipa"

echo "=== Building $APP_NAME ==="

# Clean previous build
make clean 2>/dev/null || true

# Build the .app (without packaging as .deb)
make

# Verify .app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "ERROR: $APP_BUNDLE not found!"
    echo "Theos build failed."
    exit 1
fi

echo "=== Creating .ipa ==="
mkdir -p "$OUTPUT_DIR/Payload"
cp -R "$APP_BUNDLE" "$OUTPUT_DIR/Payload/"

# Remove any previous ipa
rm -f "$OUTPUT_DIR/$IPA_NAME"

# Create ipa (zip with Payload/)
cd "$OUTPUT_DIR"
zip -r -q "$IPA_NAME" Payload/
rm -rf Payload/

echo "=== Done! ==="
echo "IPA: $OUTPUT_DIR/$IPA_NAME"
ls -lh "$OUTPUT_DIR/$IPA_NAME"
