#!/usr/bin/env fish

# --- Configuration ---
set -l RED (set_color red)
set -l GREEN (set_color green)
set -l YELLOW (set_color yellow)
set -l NORMAL (set_color normal)

# --- Cleanup ---
# Function to clean up .cppm files.
function cleanup_cppm
    echo $YELLOW"Cleaning up .cppm files..."$NORMAL
    find . -name "*.cppm" -delete
end

# Register cleanup to run when the script exits, for any reason.
functions --on-event fish_exit cleanup_cppm

# --- Environment Setup ---

# Recursively ensures LLVM is installed, installing Homebrew if necessary.
function ensure_llvm
    # Base Case: Check if Homebrew's LLVM is already installed.
    for prefix in /opt/homebrew /usr/local
        if test -f "$prefix/bin/clang"
            echo $GREEN"Found Homebrew LLVM: $prefix/bin/clang"$NORMAL
            set -gx CC "$prefix/bin/clang"
            set -gx CXX "$prefix/bin/clang++"
            return 0 # Success
        end
    end

    # Recursive Step 1: LLVM not found, check for Homebrew.
    if command -v brew &>/dev/null
        echo $YELLOW"Homebrew is installed, but LLVM is missing. Installing llvm..."$NORMAL
        brew install llvm
    else
        # Recursive Step 2: Homebrew not found, install it.
        echo $YELLOW"Homebrew not found. Installing Homebrew..."$NORMAL
        # Execute the official installer script non-interactively.
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to the path for the current session.
        if test -d /opt/homebrew/bin
             fish_add_path /opt/homebrew/bin
        end

        echo $YELLOW"Homebrew installed."$NORMAL
        ensure_llvm # Recurse to install LLVM with the new Homebrew.
    end
end

# Ensures meson is installed via Homebrew.
function ensure_meson
    # Base Case: Check if meson is already installed.
    if command -v meson &>/dev/null
        echo $GREEN"Found meson."$NORMAL
        return 0 # Success
    end

    # Meson not found, install it. Assumes Homebrew is available from ensure_llvm.
    echo $YELLOW"meson not found. Installing via Homebrew..."$NORMAL
    brew install meson
end


# --- Build Script ---

# Clean previous build artifacts.
rm -rf build builddir stup compile_commands.json bin

# Ensure build dependencies are installed.
ensure_llvm
ensure_meson

# --- Execution ---

echo $YELLOW"Building synthesis.game..."$NORMAL
# Force use of Homebrew LLVM for C++20 modules support
set -gx CC "/opt/homebrew/bin/clang"
set -gx CXX "/opt/homebrew/bin/clang++"
echo $YELLOW"CC: $CC"$NORMAL
echo $YELLOW"CXX: $CXX"$NORMAL

# Analyze module dependencies
echo $YELLOW"Analyzing module dependencies..."$NORMAL
python3 discover.py >/dev/null

# Setup meson build directory
echo $YELLOW"Setting up meson build..."$NORMAL
if test -n "$CC"; and test -n "$CXX"
    # Create a temporary native file
    echo "[binaries]" > /tmp/native.txt
    echo "c = '$CC'" >> /tmp/native.txt
    echo "cpp = '$CXX'" >> /tmp/native.txt
    meson setup build --native-file /tmp/native.txt --cross-file config/mac.txt
else
    meson setup build --cross-file config/mac.txt
end

# Create compile commands symlink and build
ln -sf build/compile_commands.json .
echo $YELLOW"Building project with ninja..."$NORMAL
ninja -C build

# Copy artifacts
echo $YELLOW"Copying artifacts to bin/..."$NORMAL
mkdir -p bin
if test -f "build/synthesis"
    cp build/synthesis bin/
    echo $GREEN"✓ Build complete. Executable at: bin/synthesis"$NORMAL
else
    echo $RED"✗ Build failed: synthesis executable not found."$NORMAL
    exit 1
end
