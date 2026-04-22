#!/bin/bash
#
# release.sh - Build release firmware for frank-nes (all platforms)
#
# Usage: ./release.sh [VERSION]
#   VERSION  - version string (e.g. "1.01"), prompted interactively if omitted
#
# Output format: frank-nes_A_BB_<platform>_<video>.uf2
#
# Build matrix (8 variants):
#   m2: hdmi_hstx, hdmi_vga, tv
#   m1: hdmi_vga, tv
#   pc: hdmi_hstx
#   dv: hdmi_vga
#   z0: hdmi_vga
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build matrix: "platform:video_suffix:cmake_video_flags"
BUILD_MATRIX=(
    "m2:hdmi_hstx:"
    "m2:hdmi_vga:-DHDMI_PIO=ON"
    "m2:tv:-DVIDEO_COMPOSITE=ON"
    "m1:hdmi_vga:"
    "m1:tv:-DVIDEO_COMPOSITE=ON"
    "pc:hdmi_hstx:"
    "dv:hdmi_vga:"
    "z0:hdmi_vga:"
)

# Version file
VERSION_FILE="version.txt"

# Read last version or initialize
if [[ -f "$VERSION_FILE" ]]; then
    read -r LAST_MAJOR LAST_MINOR < "$VERSION_FILE"
else
    LAST_MAJOR=1
    LAST_MINOR=0
fi

# Calculate next version (for default suggestion)
NEXT_MINOR=$((LAST_MINOR + 1))
NEXT_MAJOR=$LAST_MAJOR
if [[ $NEXT_MINOR -ge 100 ]]; then
    NEXT_MAJOR=$((NEXT_MAJOR + 1))
    NEXT_MINOR=0
fi

# Interactive version input
echo ""
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│                     frank-nes Release Builder                   │${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "Last version: ${YELLOW}${LAST_MAJOR}.$(printf '%02d' $LAST_MINOR)${NC}"
echo -e "Variants: ${CYAN}${#BUILD_MATRIX[@]}${NC} (m2x3, m1x2, pc, dv, z0)"
echo ""

DEFAULT_VERSION="${NEXT_MAJOR}.$(printf '%02d' $NEXT_MINOR)"

# Accept version from command line or prompt interactively
if [[ -n "$1" ]]; then
    INPUT_VERSION="$1"
    echo -e "Version (from command line): ${CYAN}${INPUT_VERSION}${NC}"
else
    read -p "Enter version [default: $DEFAULT_VERSION]: " INPUT_VERSION
    INPUT_VERSION=${INPUT_VERSION:-$DEFAULT_VERSION}
fi

# Parse version (handle both "1.00" and "1 00" formats)
if [[ "$INPUT_VERSION" == *"."* ]]; then
    MAJOR="${INPUT_VERSION%%.*}"
    MINOR="${INPUT_VERSION##*.}"
else
    read -r MAJOR MINOR <<< "$INPUT_VERSION"
fi

# Remove leading zeros for arithmetic, then re-pad
MINOR=$((10#$MINOR))
MAJOR=$((10#$MAJOR))

# Validate
if [[ $MAJOR -lt 0 ]]; then
    echo -e "${RED}Error: Major version must be >= 1${NC}"
    exit 1
fi
if [[ $MINOR -lt 0 || $MINOR -ge 100 ]]; then
    echo -e "${RED}Error: Minor version must be 0-99${NC}"
    exit 1
fi

# Format version strings
VERSION="${MAJOR}_$(printf '%02d' $MINOR)"
VERSION_DOT="${MAJOR}.$(printf '%02d' $MINOR)"
echo ""
echo -e "${GREEN}Building release version: ${VERSION_DOT}${NC}"

# Save new version
echo "$MAJOR $MINOR" > "$VERSION_FILE"

# Create release directory
RELEASE_DIR="$SCRIPT_DIR/release"
mkdir -p "$RELEASE_DIR"

SUCCEEDED=()
FAILED=()

for ENTRY in "${BUILD_MATRIX[@]}"; do
    IFS=':' read -r PLAT VIDEO_SUFFIX CMAKE_VIDEO_FLAGS <<< "$ENTRY"
    LABEL="${PLAT}_${VIDEO_SUFFIX}"
    OUTPUT_NAME="frank-nes_${VERSION}_${LABEL}.uf2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${CYAN}Building: $OUTPUT_NAME${NC}"
    echo ""

    # Clean and create build directory
    rm -rf build
    mkdir build
    cd build

    # Configure with CMake (USB HID enabled, logging disabled for release)
    if cmake ../src/platform/pico \
        -DPLATFORM="$PLAT" \
        $CMAKE_VIDEO_FLAGS \
        -DUSB_HID_ENABLED=ON \
        -DENABLE_LOGGING=0 > /dev/null 2>&1; then

        # Build
        if make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4) > /dev/null 2>&1; then
            # Copy UF2 to release directory
            if [[ -f "frank-nes.uf2" ]]; then
                cp "frank-nes.uf2" "$RELEASE_DIR/$OUTPUT_NAME"
                echo -e "  ${GREEN}✓ $LABEL${NC} → release/$OUTPUT_NAME"
                SUCCEEDED+=("$LABEL")
            else
                echo -e "  ${RED}✗ $LABEL: UF2 not found${NC}"
                FAILED+=("$LABEL")
            fi
        else
            echo -e "  ${RED}✗ $LABEL: Build failed${NC}"
            FAILED+=("$LABEL")
        fi
    else
        echo -e "  ${RED}✗ $LABEL: CMake configure failed${NC}"
        FAILED+=("$LABEL")
    fi

    cd "$SCRIPT_DIR"
done

# Clean up build directory
rm -rf build

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
    echo -e "${GREEN}Succeeded: ${SUCCEEDED[*]}${NC}"
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "${RED}Failed: ${FAILED[*]}${NC}"
fi

echo ""
echo "Release files:"
for LABEL in "${SUCCEEDED[@]}"; do
    OUTPUT_NAME="frank-nes_${VERSION}_${LABEL}.uf2"
    ls -la "$RELEASE_DIR/$OUTPUT_NAME" 2>/dev/null | awk '{printf "  %-55s (%s bytes)\n", $9, $5}'
done
echo ""
echo -e "Version: ${CYAN}${VERSION_DOT}${NC}"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Warning: ${#FAILED[@]} variant(s) failed to build${NC}"
fi

# Create GitHub release and upload all UF2s
if [[ ${#SUCCEEDED[@]} -gt 0 ]]; then
    TAG="v${VERSION_DOT}"
    echo ""
    echo -e "${CYAN}Creating GitHub release: ${TAG}${NC}"

    RELEASE_FILES=()
    for LABEL in "${SUCCEEDED[@]}"; do
        RELEASE_FILES+=("$RELEASE_DIR/frank-nes_${VERSION}_${LABEL}.uf2")
    done

    if gh release create "$TAG" "${RELEASE_FILES[@]}" \
        --title "Version ${VERSION_DOT}" \
        --generate-notes; then
        echo -e "${GREEN}✓ GitHub release created: ${TAG}${NC}"
    else
        echo -e "${YELLOW}⚠ GitHub release failed (you can upload manually)${NC}"
    fi
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    exit 1
fi
