#!/bin/bash
set -e

DYLIB_PATH=$(find .theos/obj -name "*.dylib" | head -n 1)
echo "Found compiled dylib at: $DYLIB_PATH"

if [ -f "telegram.ipa" ] && [ -s "telegram.ipa" ]; then
    echo "Unpacking official Telegram IPA..."
    unzip -q telegram.ipa -d temp_ipa
    APP_DIR=$(find temp_ipa/Payload -name "*.app" | head -n 1)
    echo "App directory is: $APP_DIR"
    mkdir -p "$APP_DIR/Frameworks"

    # 1. Download substrate dylib directly as a simple dylib inside Frameworks
    echo "Downloading substrate dylib..."
    curl -sL "https://github.com/theos/lib/raw/master/libsubstrate.dylib" -o "$APP_DIR/Frameworks/libsubstrate.dylib" || \
    curl -sL "https://github.com/CRKatri/ElleKit/releases/download/v1.1/ElleKit.dylib" -o "$APP_DIR/Frameworks/libsubstrate.dylib"

    # 2. Put Larpgram dylib inside Frameworks
    cp "$DYLIB_PATH" "$APP_DIR/Frameworks/Larpgram.dylib"

    # 3. Change dependency path in Larpgram.dylib to point to @rpath/libsubstrate.dylib
    install_name_tool -id "@rpath/Larpgram.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true
    install_name_tool -change "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "@rpath/libsubstrate.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true
    install_name_tool -change "/usr/lib/libsubstrate.dylib" "@rpath/libsubstrate.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true

    # 4. Inject LC_LOAD_DYLIB into Telegram executable
    TARGET_BIN="$APP_DIR/Telegram"
    echo "Injecting load command for libsubstrate and Larpgram into Telegram executable..."
    optool install -c load -p "@rpath/libsubstrate.dylib" -t "$TARGET_BIN" || true
    optool install -c load -p "@rpath/Larpgram.dylib" -t "$TARGET_BIN" || true

    # 5. Pseudo-sign all injected dylibs and executable
    if command -v ldid >/dev/null 2>&1; then
        ldid -S "$APP_DIR/Frameworks/libsubstrate.dylib" || true
        ldid -S "$APP_DIR/Frameworks/Larpgram.dylib" || true
        ldid -S "$TARGET_BIN" || true
    fi

    # Pack into full Telegram IPA
    echo "Repackaging clean Telegram IPA..."
    cd temp_ipa
    zip -q -r ../Larpgram-Telegram.ipa Payload
    cd ..
    rm -rf temp_ipa
    echo "Full Telegram IPA packaged cleanly!"
else
    echo "Error: telegram.ipa was not found or is empty!"
    exit 1
fi
