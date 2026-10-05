#!/bin/bash
set -e

DYLIB_PATH=$(find .theos/obj -name "*.dylib" | head -n 1)
echo "Found compiled dylib at: $DYLIB_PATH"

if [ -f "telegram.ipa" ] && [ -s "telegram.ipa" ]; then
    echo "Unpacking official Telegram IPA..."
    unzip -q telegram.ipa -d temp_ipa
    APP_DIR=$(find temp_ipa/Payload -name "*.app" | head -n 1)
    echo "Injecting into App Directory: $APP_DIR"
    
    # Copy tweak dylib into app bundle
    cp "$DYLIB_PATH" "$APP_DIR/Larpgram.dylib"
    
    # Inject load command into Telegram binary using insert_dylib or optool
    TARGET_BIN="$APP_DIR/Telegram"
    if command -v optool >/dev/null 2>&1; then
        echo "Injecting load command with optool..."
        optool install -c load -p "@executable_path/Larpgram.dylib" -t "$TARGET_BIN" || true
    fi
    
    # Resign dylib with ldid
    if command -v ldid >/dev/null 2>&1; then
        ldid -S "$APP_DIR/Larpgram.dylib" || true
    fi

    # Pack into full Telegram IPA
    echo "Zipping full injected Telegram IPA..."
    cd temp_ipa
    zip -q -r ../Larpgram-Telegram.ipa Payload
    cd ..
    rm -rf temp_ipa
    echo "Full Telegram IPA built successfully!"
else
    echo "Error: telegram.ipa was not found or is empty!"
    exit 1
fi
