#!/bin/bash
set -e

echo "=== Larpgram IPA Packaging Started ==="

DYLIB_PATH=$(find .theos/obj -name "*.dylib" 2>/dev/null | head -n 1 || true)
if [ -z "$DYLIB_PATH" ] || [ ! -f "$DYLIB_PATH" ]; then
    DYLIB_PATH=$(find . -name "Larpgram.dylib" 2>/dev/null | head -n 1 || true)
fi

echo "Found compiled dylib at: $DYLIB_PATH"

if [ ! -f "telegram.ipa" ] || [ ! -s "telegram.ipa" ]; then
    echo "Error: telegram.ipa was not found or is empty!"
    exit 1
fi

rm -rf temp_ipa
echo "Unpacking official Telegram IPA..."
unzip -q telegram.ipa -d temp_ipa
APP_DIR=$(find temp_ipa/Payload -name "*.app" | head -n 1)
echo "App directory is: $APP_DIR"

mkdir -p "$APP_DIR/Frameworks"

# 1. Clean out legacy/broken substrate dummy files if present
rm -rf "$APP_DIR/Frameworks/CydiaSubstrate.framework" "$APP_DIR/Frameworks/libsubstrate.dylib" "$APP_DIR/Frameworks/.ldid*"

# 2. Copy compiled Larpgram dylib inside Frameworks
if [ -f "$DYLIB_PATH" ]; then
    echo "Copying Larpgram.dylib to Frameworks..."
    cp "$DYLIB_PATH" "$APP_DIR/Frameworks/Larpgram.dylib"
    install_name_tool -id "@executable_path/Frameworks/Larpgram.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" 2>/dev/null || true
fi

# 3. Inject LC_LOAD_DYLIB into Telegram binary using our reliable injector
TARGET_BIN="$APP_DIR/Telegram"
echo "Injecting load command for Larpgram into Telegram executable..."
python3 inject_dylib.py dylib "$TARGET_BIN" "@executable_path/Frameworks/Larpgram.dylib"

# 4. Patch App Name (Larpgram) and Bundle Identifier (ph.telegra.larpgram)
echo "Patching Info.plist (Display Name: Larpgram, Bundle ID: ph.telegra.larpgram)..."
python3 inject_dylib.py plist "$APP_DIR" "Larpgram" "ph.telegra.larpgram"

# 5. Remove PlugIns (extensions) and Watch app (prevents crashes from App Group conflicts and unsigned extensions)
echo "Removing extensions and Watch directory to ensure flawless sideloading..."
rm -rf "$APP_DIR/PlugIns" "$APP_DIR/Watch"

# 6. Remove old AppStore CodeSignature & embedded.mobileprovision
rm -rf "$APP_DIR/_CodeSignature"
rm -f "$APP_DIR/embedded.mobileprovision"

# 7. Ad-hoc codesign binaries
echo "Ad-hoc signing binaries..."
if command -v codesign >/dev/null 2>&1; then
    codesign -f -s - "$APP_DIR/Frameworks/Larpgram.dylib" 2>/dev/null || true
    codesign -f -s - "$TARGET_BIN" 2>/dev/null || true
fi

if command -v ldid >/dev/null 2>&1; then
    ldid -S "$APP_DIR/Frameworks/Larpgram.dylib" 2>/dev/null || true
    ldid -S "$TARGET_BIN" 2>/dev/null || true
fi

# 8. Repack into Larpgram-Telegram.ipa
echo "Repackaging clean Larpgram-Telegram.ipa..."
rm -f Larpgram-Telegram.ipa
cd temp_ipa
zip -q -r ../Larpgram-Telegram.ipa Payload
cd ..
rm -rf temp_ipa

echo "=== Larpgram-Telegram.ipa successfully generated! ==="
ls -lh Larpgram-Telegram.ipa
