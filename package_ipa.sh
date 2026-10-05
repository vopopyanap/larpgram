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

    # 1. Provide a complete, valid CydiaSubstrate.framework bundle with Info.plist
    echo "Creating valid CydiaSubstrate.framework with Info.plist..."
    mkdir -p "$APP_DIR/Frameworks/CydiaSubstrate.framework"
    curl -sL "https://github.com/theos/lib/raw/master/libsubstrate.dylib" -o "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"
    
    cat << 'EOF' > "$APP_DIR/Frameworks/CydiaSubstrate.framework/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CydiaSubstrate</string>
    <key>CFBundleIdentifier</key>
    <string>org.saurik.CydiaSubstrate</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CydiaSubstrate</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>12.0</string>
</dict>
</plist>
EOF

    # 2. Also keep libsubstrate.dylib flat copy
    cp "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "$APP_DIR/Frameworks/libsubstrate.dylib"

    # 3. Put Larpgram dylib inside Frameworks
    cp "$DYLIB_PATH" "$APP_DIR/Frameworks/Larpgram.dylib"
    install_name_tool -id "@rpath/Larpgram.dylib" "$APP_DIR/Frameworks/Larpgram.dylib" || true

    # 4. Inject LC_LOAD_DYLIB into Telegram executable
    TARGET_BIN="$APP_DIR/Telegram"
    echo "Injecting load command for Larpgram into Telegram executable..."
    optool install -c load -p "@rpath/Larpgram.dylib" -t "$TARGET_BIN" || true

    # 5. Native ad-hoc code signing using codesign and ldid
    echo "Signing binaries and frameworks..."
    codesign -f -s - "$APP_DIR/Frameworks/CydiaSubstrate.framework" || true
    codesign -f -s - "$APP_DIR/Frameworks/libsubstrate.dylib" || true
    codesign -f -s - "$APP_DIR/Frameworks/Larpgram.dylib" || true
    codesign -f -s - "$TARGET_BIN" || true

    if command -v ldid >/dev/null 2>&1; then
        ldid -S "$APP_DIR/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" || true
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
