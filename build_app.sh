#!/bin/bash

# Parse command line arguments
BUILD_TYPE="debug"
RUN_AFTER_BUILD=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--release) BUILD_TYPE="release" ;;
        --run) RUN_AFTER_BUILD=true ;;
        -h|--help)
            echo "Usage: ./build_app.sh [options]"
            echo "Options:"
            echo "  -r, --release    Build in release mode"
            echo "  --run            Run the app after building"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Set variables
APP_NAME="MacOSChatApp"
BUILD_DIR=".build/$BUILD_TYPE"
APP_BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
FRAMEWORKS_DIR="$CONTENTS_DIR/Frameworks"

# Build the app
echo "=== Building $APP_NAME ==="
if [ "$BUILD_TYPE" = "release" ]; then
    swift build -c release
else
    swift build
fi

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "Build failed. Exiting."
    exit 1
fi

# Create app bundle structure
echo "=== Creating app bundle ==="
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$FRAMEWORKS_DIR"

# Copy executable
echo "=== Copying executable ==="
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# Copy Info.plist
echo "=== Copying Info.plist ==="
cp "MacOSChatApp/Info.plist" "$CONTENTS_DIR/"

# Copy entitlements
echo "=== Copying entitlements ==="
cp "MacOSChatApp/MacOSChatApp.entitlements" "$RESOURCES_DIR/"

# Create PkgInfo
echo "=== Creating PkgInfo ==="
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Set permissions
echo "=== Setting permissions ==="
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy to Applications folder if requested
if [ "$1" == "--install" ]; then
    echo "=== Installing to Applications folder ==="
    cp -R "$APP_BUNDLE_DIR" "/Applications/"
    echo "Installed to /Applications/$APP_NAME.app"
fi

echo "=== Build completed successfully ==="
echo "App bundle created at: $APP_BUNDLE_DIR"
echo "You can run the app by double-clicking on it in Finder"
echo "Or by running: open $APP_BUNDLE_DIR"
