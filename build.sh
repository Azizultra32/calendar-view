#!/bin/bash

# Build and run the CircularTimelineContacts app

echo "Building CircularTimelineContacts app..."

# Create build directory
mkdir -p build

# Compile all Swift files
swiftc CircularTimelineContacts/*.swift \
    -o build/CircularTimelineContacts \
    -target x86_64-apple-macos13.0 \
    -framework SwiftUI \
    -framework Foundation \
    -parse-as-library

echo "Build complete!"
echo "Note: To run as a proper macOS app, you'll need to open this project in Xcode."