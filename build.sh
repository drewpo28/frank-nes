#!/bin/bash
set -e

BUILD_DIR="build"
CMAKE_OPTS="-DPICO_PLATFORM=rp2350"

# Platform selection (default: m2)
# Usage: PLATFORM=dv ./build.sh
PLATFORM="${PLATFORM:-m2}"
CMAKE_OPTS="$CMAKE_OPTS -DPLATFORM=$PLATFORM"

# Optional: embed a ROM file
# Usage: NES_ROM=path/to/game.nes ./build.sh
if [ -n "$NES_ROM" ]; then
    # Resolve to absolute path
    NES_ROM_ABS="$(cd "$(dirname "$NES_ROM")" && pwd)/$(basename "$NES_ROM")"
    CMAKE_OPTS="$CMAKE_OPTS -DNES_ROM_PATH=$NES_ROM_ABS"
fi

# Optional: CPU speed (252, 378, 504)
if [ -n "$CPU_SPEED" ]; then
    CMAKE_OPTS="$CMAKE_OPTS -DCPU_SPEED=$CPU_SPEED"
fi

# Optional: video mode (240p or 480p)
if [ -n "$VIDEO_MODE" ]; then
    CMAKE_OPTS="$CMAKE_OPTS -DVIDEO_MODE=$VIDEO_MODE"
fi

# Optional: composite TV output instead of HDMI (m1 and m2 only)
# Usage: VIDEO_COMPOSITE=1 ./build.sh
if [ "${VIDEO_COMPOSITE:-0}" = "1" ]; then
    CMAKE_OPTS="$CMAKE_OPTS -DVIDEO_COMPOSITE=ON"
fi

# Optional: PIO-based HDMI output (auto-selected for m1, dv, z0)
# Usage: HDMI_PIO=1 ./build.sh
if [ "${HDMI_PIO:-0}" = "1" ]; then
    CMAKE_OPTS="$CMAKE_OPTS -DHDMI_PIO=ON"
fi

# USB HID host mode (disabled by default for USB serial logging)
# Usage: USB_HID=1 ./build.sh  to enable (release builds use release.sh)
if [ "${USB_HID:-0}" = "1" ]; then
    CMAKE_OPTS="$CMAKE_OPTS -DUSB_HID_ENABLED=ON"
else
    CMAKE_OPTS="$CMAKE_OPTS -DUSB_HID_ENABLED=OFF"
fi

# Clean build dir if platform or video output mode changed (CMake caches these)
if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
    CACHED_PLAT=$(grep -s 'PLATFORM:STRING=' "$BUILD_DIR/CMakeCache.txt" | cut -d= -f2)
    CACHED_COMP=$(grep -s 'VIDEO_COMPOSITE:BOOL=' "$BUILD_DIR/CMakeCache.txt" | cut -d= -f2)
    CACHED_PIO=$(grep -s 'HDMI_PIO:BOOL=' "$BUILD_DIR/CMakeCache.txt" | cut -d= -f2)
    WANTED_COMP="OFF"
    WANTED_PIO="OFF"
    [ "${VIDEO_COMPOSITE:-0}" = "1" ] && WANTED_COMP="ON"
    [ "${HDMI_PIO:-0}" = "1" ] && WANTED_PIO="ON"
    if [ "$CACHED_PLAT" != "$PLATFORM" ] || \
       [ "$CACHED_COMP" != "$WANTED_COMP" ] || \
       [ "$CACHED_PIO" != "$WANTED_PIO" ]; then
        rm -rf "$BUILD_DIR"
    fi
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake $CMAKE_OPTS ../src/platform/pico
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "Build complete ($PLATFORM). Firmware: build/frank-nes.uf2"
