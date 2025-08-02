#!/bin/bash

# Build script for Metal Swift library for C# interop

# Exit on error
set -e

echo "Building Metal Swift library..."

# Create build directory if it doesn't exist
rm -rf ./build
mkdir -p build

# Use xcrun to ensure correct toolchain
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Compile Swift files into a dynamic library
swiftc -emit-library \
    -o build/lib-synthesis.dylib \
    -Xlinker -install_name -Xlinker @rpath/lib-synthesis.dylib \
    -target arm64-apple-macos13.0 \
    -sdk $(xcrun --sdk macosx --show-sdk-path) \
    -framework Metal \
    -framework MetalKit \
    -framework Cocoa \
    -framework Foundation \
    src/Lib.swift \
    src/Big.swift \
    src/Camera.swift \
    src/Index.swift \
    src/Controller.swift \
    src/Tree.swift \
    src/Block.swift \
    src/Palette.swift \
    src/Render.swift

# Copy shader file to build directory
cp src/shader.metal build/shader.metal

echo "Build complete!"
