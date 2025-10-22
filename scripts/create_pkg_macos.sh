#!/usr/bin/env bash
set -euo pipefail

INSTALL_BUNDLE=$1
OUTPUT_PKG=${2:-"AltErgo-dev.pkg"}

APP_NAME="alt-ergo"
APP_FULLNAME="Alt-Ergo SMT Solver"
APP_VERSION="dev"
BUNDLE_ID="com.ocamlpro.alt-ergo"
MAIN_BINARY="bin/alt-ergo"

APP_NAME_CAP="AltErgo"
BINARY_NAME="alt-ergo"
BINARY_SRC="$INSTALL_BUNDLE/$MAIN_BINARY"

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

APP_BUNDLE="$WORK_DIR/${APP_NAME_CAP}.app"
mkdir -p "$APP_BUNDLE/Contents"/{MacOS,Frameworks,Resources}

cp -R "$INSTALL_BUNDLE"/* "$APP_BUNDLE/Contents/Resources/"
cp "$BINARY_SRC" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"

BINARY_DST="$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"

dylibs=$(otool -L "$BINARY_DST" 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v "^/usr/lib/" | grep -v "^/System/" | grep -v "^@" || true)

if [ -n "$dylibs" ]; then
  for dylib_path in $dylibs; do
    if [ -f "$dylib_path" ]; then
      dylib_name=$(basename "$dylib_path")
      cp "$dylib_path" "$APP_BUNDLE/Contents/Frameworks/$dylib_name"
      install_name_tool -change "$dylib_path" "@executable_path/../Frameworks/$dylib_name" "$BINARY_DST" 2>/dev/null || true
    fi
  done
fi

codesign -s - -f "$BINARY_DST" 2>/dev/null || true

cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$BINARY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_FULLNAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_FULLNAME</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

SCRIPTS_DIR="$WORK_DIR/scripts"
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/postinstall" << EOF
#!/bin/bash
mkdir -p /usr/local/bin
ln -sf "/Applications/${APP_NAME_CAP}.app/Contents/MacOS/${BINARY_NAME}" "/usr/local/bin/${BINARY_NAME}"

if [ -d "/Applications/${APP_NAME_CAP}.app/Contents/Resources/man" ]; then
  mkdir -p /usr/local/share/man
  for section_dir in /Applications/${APP_NAME_CAP}.app/Contents/Resources/man/*; do
    if [ -d "\$section_dir" ]; then
      section=\$(basename "\$section_dir")
      mkdir -p /usr/local/share/man/\${section}
      for manpage in "\$section_dir"/*; do
        [ -f "\$manpage" ] && ln -sf "\$manpage" "/usr/local/share/man/\${section}/\$(basename "\$manpage")"
      done
    fi
  done
fi
exit 0
EOF

chmod +x "$SCRIPTS_DIR/postinstall"

COMPONENT_PKG="${OUTPUT_PKG%.pkg}-component.pkg"

pkgbuild \
  --root "$APP_BUNDLE" \
  --identifier "$BUNDLE_ID" \
  --version "$APP_VERSION" \
  --install-location "/Applications/${APP_NAME_CAP}.app" \
  --scripts "$SCRIPTS_DIR" \
  "$COMPONENT_PKG" >/dev/null

productbuild \
  --package "$COMPONENT_PKG" \
  "$OUTPUT_PKG" >/dev/null

rm -f "$COMPONENT_PKG"

echo "$OUTPUT_PKG created"
