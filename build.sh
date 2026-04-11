#!/bin/bash
# Build ghostel and its vendored dependencies.
#
# This script:
# 1. Builds libghostty-vt from the vendored ghostty submodule
# 2. Copies bundled dependency libraries (simdutf, highway) to stable paths
# 3. Builds the ghostel Emacs dynamic module
set -e

cd "$(dirname "$0")"

# Parse options
ZIG_TARGET=""
while getopts "t:" opt; do
    case "$opt" in
        t) ZIG_TARGET="$OPTARG" ;;
        *) echo "Usage: $0 [-t zig-target-triple]"; exit 1 ;;
    esac
done

# Build target flags for zig
ZIG_TARGET_FLAG=""
if [ -n "$ZIG_TARGET" ]; then
    ZIG_TARGET_FLAG="-Dtarget=$ZIG_TARGET"
fi

# Check submodule
if [ ! -f vendor/ghostty/build.zig ]; then
    echo "Initializing ghostty submodule..."
    git submodule update --init vendor/ghostty
fi

# Build libghostty-vt
echo "Building libghostty-vt..."
if [ -n "$ZIG_TARGET" ]; then
    # When cross-compiling, use an isolated cache so that find does not pick up
    # host-architecture .a files from a shared or restored zig cache.
    GHOSTTY_CACHE="$(pwd)/vendor/ghostty/.zig-cache-$ZIG_TARGET"
    (cd vendor/ghostty && \
     ZIG_LOCAL_CACHE_DIR="$GHOSTTY_CACHE" ZIG_GLOBAL_CACHE_DIR="$GHOSTTY_CACHE" \
     zig build -Demit-lib-vt=true -Doptimize=ReleaseFast $ZIG_TARGET_FLAG)
    SEARCH_DIRS="$GHOSTTY_CACHE"
else
    (cd vendor/ghostty && zig build -Demit-lib-vt=true -Doptimize=ReleaseFast -Dcpu=baseline)
    SEARCH_DIRS="vendor/ghostty/.zig-cache"
    [ -n "$ZIG_LOCAL_CACHE_DIR" ] && SEARCH_DIRS="$SEARCH_DIRS $ZIG_LOCAL_CACHE_DIR"
    [ -n "$ZIG_GLOBAL_CACHE_DIR" ] && SEARCH_DIRS="$SEARCH_DIRS $ZIG_GLOBAL_CACHE_DIR"
fi

# Copy bundled C++ dependencies to stable paths.
# These are built by ghostty's zig build into a cache directory with
# hash-based names.
echo "Copying dependency libraries..."

SIMDUTF=""
HIGHWAY=""
for dir in $SEARCH_DIRS; do
    [ -d "$dir" ] || continue
    [ -z "$SIMDUTF" ] && SIMDUTF=$(find "$dir" -name "libsimdutf.a" -print -quit 2>/dev/null)
    [ -z "$HIGHWAY" ] && HIGHWAY=$(find "$dir" -name "libhighway.a" -print -quit 2>/dev/null)
done

if [ -z "$SIMDUTF" ]; then
    echo "Error: could not find libsimdutf.a in vendor/ghostty/.zig-cache"
    exit 1
fi
if [ -z "$HIGHWAY" ]; then
    echo "Error: could not find libhighway.a in vendor/ghostty/.zig-cache"
    exit 1
fi

cp "$SIMDUTF" vendor/ghostty/zig-out/lib/libsimdutf.a
cp "$HIGHWAY" vendor/ghostty/zig-out/lib/libhighway.a
echo "  libsimdutf.a <- $SIMDUTF"
echo "  libhighway.a <- $HIGHWAY"

# Build ghostel module
echo "Building ghostel module..."
if [ -n "$ZIG_TARGET" ]; then
    zig build -Doptimize=ReleaseFast $ZIG_TARGET_FLAG
else
    zig build -Doptimize=ReleaseFast -Dcpu=baseline
fi

# Determine output suffix from target or host OS
if [ -n "$ZIG_TARGET" ]; then
    case "$ZIG_TARGET" in
        *macos*|*darwin*) MODULE_SUFFIX=".dylib" ;;
        *)                MODULE_SUFFIX=".so" ;;
    esac
else
    case "$(uname -s)" in
        Darwin) MODULE_SUFFIX=".dylib" ;;
        *)      MODULE_SUFFIX=".so" ;;
    esac
fi
echo "Done! ghostel-module${MODULE_SUFFIX} is ready."
echo "Load in Emacs with: (require 'ghostel)"
