#!/bin/bash

# Script to create a DMG file for MacOSChatApp

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default variables
APP_NAME="MacOSChatApp"
DISPLAY_NAME="BionicChat" # The name that will be shown in the DMG
BUILD_TYPE="debug"
INCLUDE_APPLICATIONS_LINK=false
CUSTOM_DMG_NAME="bionicChat" # Default DMG name
SKIP_BUILD=false
CLEAN_BUILD=false
MIN_DISK_SPACE=300 # Minimum disk space required in MB
FORCE_BUILD=false # Override disk space check

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}=== $1 ===${NC}\n"
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 successful${NC}"
    else
        echo -e "${RED}✗ $1 failed${NC}"
        exit 1
    fi
}

# Function to display help
show_help() {
    echo "Usage: ./create_dmg.sh [options]"
    echo "Options:"
    echo "  -r, --release            Build in release mode (default: debug)"
    echo "  -a, --add-applications   Include a link to /Applications in the DMG"
    echo "  -n, --name NAME          Specify a custom name for the DMG file"
    echo "  -s, --skip-build         Skip building the app (use existing app bundle)"
    echo "  -c, --clean              Clean build directory before building"
    echo "  -f, --force              Force build even with low disk space"
    echo "  -h, --help               Show this help message"
    exit 0
}

# Function to check available disk space
check_disk_space() {
    # Skip check if force build is enabled
    if [ "$FORCE_BUILD" = true ]; then
        echo "Force build enabled, skipping disk space check"
        return 0
    fi
    
    # Get available disk space in MB
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        AVAILABLE_SPACE=$(df -m . | tail -1 | awk '{print $4}')
    else
        # Linux and others
        AVAILABLE_SPACE=$(df -m . | tail -1 | awk '{print $4}')
    fi
    
    echo "Available disk space: ${AVAILABLE_SPACE}MB"
    
    if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE" ]; then
        echo -e "${RED}Error: Not enough disk space. At least ${MIN_DISK_SPACE}MB required, but only ${AVAILABLE_SPACE}MB available.${NC}"
        echo "Try using the --clean option to remove previous build artifacts."
        echo "Or use the --force option to build anyway (not recommended)."
        exit 1
    fi
}

# Function to clean build directory
clean_build_dir() {
    print_section "Cleaning build directory"
    if [ -d ".build" ]; then
        rm -rf .build
        check_status "Cleaning .build directory"
    fi
    
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
        check_status "Cleaning temporary directory"
    fi
    
    if [ -f "$DMG_NAME" ]; then
        rm -f "$DMG_NAME"
        check_status "Removing existing DMG file"
    fi
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--release) BUILD_TYPE="release" ;;
        -a|--add-applications) INCLUDE_APPLICATIONS_LINK=true ;;
        -n|--name) 
            CUSTOM_DMG_NAME="$2"
            shift
            ;;
        -s|--skip-build) SKIP_BUILD=true ;;
        -c|--clean) CLEAN_BUILD=true ;;
        -f|--force) FORCE_BUILD=true ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter: $1"; show_help ;;
    esac
    shift
done

# Set derived variables based on arguments
BUILD_DIR=".build/$BUILD_TYPE"
APP_BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
TMP_DIR="tmp_dmg"
VOLUME_NAME="$DISPLAY_NAME"

# Set DMG name based on arguments
if [ -n "$CUSTOM_DMG_NAME" ]; then
    DMG_NAME="$CUSTOM_DMG_NAME.dmg"
else
    DMG_NAME="$DISPLAY_NAME.dmg"
fi

print_section "Configuration"
echo "App name: $APP_NAME"
echo "Display name: $DISPLAY_NAME"
echo "Build type: $BUILD_TYPE"
echo "DMG name: $DMG_NAME"
echo "Include Applications link: $INCLUDE_APPLICATIONS_LINK"
echo "Skip build: $SKIP_BUILD"
echo "Clean build: $CLEAN_BUILD"
echo "Force build: $FORCE_BUILD"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ]; then
    clean_build_dir
fi

# Check disk space
check_disk_space

# Build the app if not skipped
if [ "$SKIP_BUILD" = false ]; then
    # Build the app bundle first
    print_section "Building app bundle"
    if [ "$BUILD_TYPE" = "release" ]; then
        ./build.sh --release
    else
        ./build.sh
    fi
    check_status "App build"

    # Create the app bundle
    print_section "Creating app bundle"
    if [ "$BUILD_TYPE" = "release" ]; then
        ./build_app.sh --release
    else
        ./build_app.sh
    fi
    check_status "App bundle creation"
fi

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE_DIR" ]; then
    echo -e "${RED}App bundle not found at $APP_BUNDLE_DIR${NC}"
    exit 1
fi

# Create temporary directory for DMG contents
print_section "Creating DMG"
mkdir -p "$TMP_DIR"
check_status "Temporary directory creation"

# Copy app bundle to temporary directory
cp -R "$APP_BUNDLE_DIR" "$TMP_DIR/"
check_status "Copying app bundle"

# Rename the app bundle to the display name
if [ "$APP_NAME" != "$DISPLAY_NAME" ]; then
    print_section "Renaming app bundle"
    mv "$TMP_DIR/$APP_NAME.app" "$TMP_DIR/$DISPLAY_NAME.app"
    check_status "Renaming app bundle"
fi

# Clean user data from the app bundle
print_section "Cleaning user data"
echo "Ensuring no user data is included in the DMG"

# The app stores data in ~/Library/Application Support/MacOSChatApp/
# We don't need to modify the app bundle for this, as the database is created on first launch
# But we should document this for clarity
echo "App data will be stored in ~/Library/Application Support/MacOSChatApp/ when the app is run"
echo "No pre-existing conversations or profiles will be included in the DMG"

# Add symlink to /Applications if requested
if [ "$INCLUDE_APPLICATIONS_LINK" = true ]; then
    echo "Adding symlink to /Applications"
    ln -s /Applications "$TMP_DIR/Applications"
    check_status "Adding Applications symlink"
fi

# Create DMG file
print_section "Creating DMG file"
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$TMP_DIR" -ov -format UDZO "$DMG_NAME"
check_status "DMG creation"

# Clean up
print_section "Cleaning up"
rm -rf "$TMP_DIR"
check_status "Cleanup"

print_section "DMG Creation Complete"
echo -e "DMG file created at: ${GREEN}$DMG_NAME${NC}"
echo -e "You can distribute this DMG file to users."

# Show file info
ls -lh "$DMG_NAME"
