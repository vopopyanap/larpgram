#!/bin/bash
set -e

DYLIB_PATH=$(find .theos/obj -name "*.dylib" | head -n 1)
echo "Found dylib at: $DYLIB_PATH"

if [ -f "telegram.ipa" ] && [ -s "telegram.ipa" ]; then
    echo "Unpacking official Telegram IPA..."
    unzip -q telegram.ipa -d temp_ipa
    APP_DIR=$(find temp_ipa/Payload -name "*.app" | head -n 1)
    cp "$DYLIB_PATH" "$APP_DIR/Larpgram.dylib"
    cd temp_ipa
    zip -q -r ../Larpgram-Telegram.ipa Payload
    cd ..
else
    echo "Packaging standalone bundle..."
    mkdir -p Payload/Telegram.app
    cp "$DYLIB_PATH" Payload/Telegram.app/Larpgram.dylib
    cat << 'EOF' > Payload/Telegram.app/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Telegram</string>
    <key>CFBundleIdentifier</key>
    <string>ph.telegra.Telegraph</string>
    <key>CFBundleName</key>
    <string>Larpgram</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
    zip -q -r Larpgram-Telegram.ipa Payload
fi

echo "Packaging complete!"
