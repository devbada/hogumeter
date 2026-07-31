#!/bin/bash

# =============================================================================
# HoguMeter App Store Screenshot Capture Script
# =============================================================================
#
# This script captures screenshots from Xcode Previews using simctl.
# Run this script from the project root directory.
#
# Requirements:
# - Xcode 15+
# - iPhone 15 Pro Max simulator installed
#
# Usage:
#   ./AppStoreScreenshots/capture_screenshots.sh
#
# =============================================================================

set -e

# Configuration
SIMULATOR_NAME="iPhone 15 Pro Max"
OUTPUT_DIR="AppStoreScreenshots/iPhone"
PROJECT_ROOT=$(pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== HoguMeter Screenshot Capture ===${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Find the simulator UDID
echo -e "${YELLOW}Finding simulator...${NC}"
SIMULATOR_UDID=$(xcrun simctl list devices | grep "$SIMULATOR_NAME" | grep -v unavailable | head -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$SIMULATOR_UDID" ]; then
    echo -e "${RED}Error: Could not find $SIMULATOR_NAME simulator${NC}"
    echo "Available simulators:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

echo -e "${GREEN}Found: $SIMULATOR_NAME ($SIMULATOR_UDID)${NC}"
echo ""

# Boot simulator if needed
BOOT_STATUS=$(xcrun simctl list devices | grep "$SIMULATOR_UDID" | grep -o "(Booted)" || echo "")
if [ -z "$BOOT_STATUS" ]; then
    echo -e "${YELLOW}Booting simulator...${NC}"
    xcrun simctl boot "$SIMULATOR_UDID"
    sleep 5
fi

# Open Simulator app
echo -e "${YELLOW}Opening Simulator...${NC}"
open -a Simulator

# Wait for simulator to be ready
sleep 3

echo ""
echo -e "${GREEN}=== Screenshot Capture Instructions ===${NC}"
echo ""
echo "The simulator is now running. To capture App Store screenshots:"
echo ""
echo "1. Open Xcode and navigate to:"
echo "   HoguMeter/Presentation/Views/AppStoreScreenshots.swift"
echo ""
echo "2. In Xcode Preview, select each preview:"
echo "   - 1. 메인 화면 (대기)"
echo "   - 2. 주행 중"
echo "   - 3. 영수증"
echo "   - 4. 설정"
echo "   - 5. 지역별 요금"
echo "   - 6. 주행 기록"
echo ""
echo "3. For each preview, capture screenshot:"
echo "   - Press Cmd+Shift+4 then Space to capture window"
echo "   - Or use: xcrun simctl io booted screenshot <filename>.png"
echo ""
echo "4. Alternatively, capture from simulator directly:"
echo ""

# Function to capture screenshot
capture_screenshot() {
    local name=$1
    local filename="$OUTPUT_DIR/${name}.png"
    echo -e "${YELLOW}Capturing: $filename${NC}"
    xcrun simctl io "$SIMULATOR_UDID" screenshot "$filename"
    echo -e "${GREEN}Saved: $filename${NC}"
}

echo "Quick capture commands (run while app screen is visible):"
echo ""
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/01_main_idle.png"
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/02_main_running.png"
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/03_receipt.png"
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/04_settings.png"
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/05_region_fares.png"
echo "  xcrun simctl io booted screenshot $OUTPUT_DIR/06_history.png"
echo ""

echo -e "${GREEN}=== Manual Capture Mode ===${NC}"
echo ""
echo "Press Enter to capture current simulator screen, or 'q' to quit."
echo "Enter filename (without extension) when prompted."
echo ""

while true; do
    read -p "Filename (or 'q' to quit): " filename
    if [ "$filename" = "q" ]; then
        echo -e "${GREEN}Done!${NC}"
        break
    fi
    if [ -n "$filename" ]; then
        capture_screenshot "$filename"
    fi
done

echo ""
echo -e "${GREEN}Screenshots saved to: $OUTPUT_DIR${NC}"
echo ""
echo "App Store Requirements:"
echo "  - iPhone: 1284 x 2778 pixels (6.7\" display)"
echo "  - Format: PNG or JPEG"
echo "  - No transparency"
echo ""
