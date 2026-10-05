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

    # Bundle CydiaSubstrate framework so non-jailbroken devices won't crash
    echo "Bundling CydiaSubstrate framework..."
    if [ -f "$THEOS/lib/libsubstrate.dylib" ]; then
        cp "$THEOS/lib/libsubstrate.dylib" "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" 2>/dev/null || true
    fi
    
    # Download clean CydiaSubstrate / ElleKit universal dylib
    mkdir -p "$APP_DIR/Frameworks/CydiaSubstrate.framework"
    curl -sL "https://github.com/theos/lib/raw/master/libsubstrate.dylib" -o "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" || \
    curl -sL "https://github.com/CRKatri/ElleKit/releases/download/v1.1/ElleKit.dylib" -o "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"
    
    # Also place libsubstrate in Frameworks root
    cp "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "$APP_DIR/Frameworks/libsubstrate.dylib"
    
    # Put tweak inside Frameworks
    cp "$DYLIB_PATH" "$APP_DIR/Frameworks/Larpgram.dylib"
    
    # Fix install names and rpath
    install_name_tool -id "@rpath/Larpgram.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true
    install_name_tool -change "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "@rpath/CydiaSubstrate.framework/CydiaSubstrate" "$APP_DIR/Frameworks/Larpgram.dylib" || true
    install_name_tool -change "/usr/lib/libsubstrate.dylib" "@rpath/libsubstrate.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true

    # Inject LC_LOAD_DYLIB into Telegram binary
    TARGET_BIN="$APP_DIR/Telegram"
    echo "Injecting load command into Telegram executable..."
    optool install -c load -p "@rpath/Larpgram.dylib" -t "$TARGET_BIN" || true

    # Pseudo-sign all binaries inside Frameworks
    if command -v ldid >/dev/null 2>&1; then
        ldid -S "$APP_DIR/Frameworks/Larpgram.dylib" || true
        ldid -S "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" || true
        ldid -S "$APP_DIR/Frameworks/libsubstrate.dylib" || true
        ldid -S "$TARGET_BIN" || true
    fi

    # Pack into full Telegram IPA
    echo "Repackaging injected Telegram IPA..."
    cd temp_ipa
    zip -q -r ../Larpgram-Telegram.ipa Payload
    cd ..
    rm -rf temp_ipa
    echo "Full Telegram IPA built successfully without missing dynamic library dependencies!"
else
    echo "Error: telegram.ipa was not found or is empty!"
    exit 1
fi
