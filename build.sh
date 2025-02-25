#!/bin/bash

# Build and run script for MacOSChatApp

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Make script executable
chmod +x build.sh

# Check if Swift is installed
print_section "Checking Swift installation"
if ! command -v swift &> /dev/null; then
    echo -e "${RED}Swift is not installed. Please install Swift before continuing.${NC}"
    exit 1
fi
echo -e "${GREEN}Swift is installed: $(swift --version | head -n 1)${NC}"

# Parse command line arguments
BUILD_TYPE="debug"
RUN_AFTER_BUILD=false
RUN_TESTS=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--release) BUILD_TYPE="release" ;;
        --run) RUN_AFTER_BUILD=true ;;
        -t|--test) RUN_TESTS=true ;;
        -h|--help)
            echo "Usage: ./build.sh [options]"
            echo "Options:"
            echo "  -r, --release    Build in release mode"
            echo "  --run            Run the app after building"
            echo "  -t, --test       Run tests"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Resolve dependencies
print_section "Resolving dependencies"
swift package resolve
check_status "Dependency resolution"

# Run tests if requested
if [ "$RUN_TESTS" = true ]; then
    print_section "Running tests"
    swift test
    check_status "Tests"
    exit 0
fi

# Build the project
print_section "Building project in $BUILD_TYPE mode"
swift build -c $BUILD_TYPE
check_status "Build"

# Run the app if requested
if [ "$RUN_AFTER_BUILD" = true ]; then
    print_section "Running MacOSChatApp"
    if [ "$BUILD_TYPE" = "release" ]; then
        .build/release/MacOSChatApp
    else
        .build/debug/MacOSChatApp
    fi
fi

print_section "Build completed successfully"
echo "You can run the app with:"
if [ "$BUILD_TYPE" = "release" ]; then
    echo "  .build/release/MacOSChatApp"
else
    echo "  .build/debug/MacOSChatApp"
fi
