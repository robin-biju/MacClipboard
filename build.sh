#!/bin/bash

# Exit on error
set -e

APP_NAME="MacClipboard"
APP_BUNDLE="${APP_NAME}.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"

echo "🧹 Cleaning previous build..."
rm -rf "$APP_BUNDLE"

echo "📁 Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

echo "📋 Copying Info.plist and Icon..."
cp Info.plist "${APP_BUNDLE}/Contents/"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${APP_BUNDLE}/Contents/Resources/"
fi

echo "🔨 Compiling Swift source files..."
# We compile with -parse-as-library because we are using @main in SwiftUI
swiftc ClipboardManager.swift ContentView.swift SettingsView.swift MacClipboardApp.swift \
    -o "${MACOS_DIR}/${APP_NAME}" \
    -parse-as-library \
    -target arm64-apple-macosx13.0

echo "📦 Packaging for distribution..."
zip -q -r -y MacClipboard.zip "$APP_BUNDLE"

echo "✅ Build complete! App created at $APP_BUNDLE and zipped at MacClipboard.zip"
