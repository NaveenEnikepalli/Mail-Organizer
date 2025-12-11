#!/bin/bash

###############################################################################
#                    Mail Mind — Auto-Run on Android Device                  #
#                                                                             #
# This script detects connected Android devices and runs the Flutter app     #
# automatically on the first available device (USB or WiFi debugging).       #
#                                                                             #
# Usage:                                                                      #
#   ./run_on_device.sh                    (run in debug mode)               #
#   ./run_on_device.sh --release          (run in release mode)             #
#   ./run_on_device.sh --verbose          (show detailed output)            #
#                                                                             #
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_MODE="debug"
VERBOSE=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --release)
      BUILD_MODE="release"
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [--release] [--verbose]"
      exit 1
      ;;
  esac
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         Mail Mind — Android Device Deployment Tool            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Detect devices
echo "[1/4] Detecting Android devices..."
echo ""

DEVICES_OUTPUT=$(flutter devices 2>&1)

if [[ $VERBOSE == true ]]; then
  echo "$DEVICES_OUTPUT"
  echo ""
fi

# Extract device IDs (filter out emulator and desktop)
ANDROID_DEVICES=$(echo "$DEVICES_OUTPUT" | grep -E '^\w+.*android.*connected' | awk '{print $1}')

if [ -z "$ANDROID_DEVICES" ]; then
  echo "❌ ERROR: No connected Android device detected."
  echo ""
  echo "Troubleshooting:"
  echo "  1. Connect Android phone via USB cable"
  echo "  2. Enable USB debugging on the phone:"
  echo "     Settings → Developer Options → USB Debugging (enabled)"
  echo "  3. Allow USB debugging permission when prompted on phone"
  echo "  4. Try again: ./run_on_device.sh"
  echo ""
  echo "Alternative: WiFi Debugging"
  echo "  1. Enable Developer Options on phone"
  echo "  2. Enable 'Wireless Debugging'"
  echo "  3. Run: adb connect <phone-ip>:5555"
  echo "  4. Try again: ./run_on_device.sh"
  echo ""
  exit 1
fi

# Get the first device
DEVICE_ID=$(echo "$ANDROID_DEVICES" | head -n1)

echo "✓ Device detected: $DEVICE_ID"
echo ""

# Step 2: Build
echo "[2/4] Building Flutter app (mode: $BUILD_MODE)..."
echo ""

if [[ $BUILD_MODE == "release" ]]; then
  if flutter build apk --release > /dev/null 2>&1; then
    echo "✓ Build successful"
  else
    echo "❌ Build failed. Run with --verbose for details:"
    flutter build apk --release
    exit 1
  fi
else
  if flutter build apk > /dev/null 2>&1; then
    echo "✓ Build successful"
  else
    echo "❌ Build failed. Run with --verbose for details:"
    flutter build apk
    exit 1
  fi
fi
echo ""

# Step 3: Install
echo "[3/4] Installing APK on device..."
echo ""

if flutter install -d "$DEVICE_ID" > /dev/null 2>&1; then
  echo "✓ Installation successful"
else
  echo "❌ Installation failed. Trying with uninstall..."
  flutter uninstall -d "$DEVICE_ID" 2>/dev/null || true
  flutter install -d "$DEVICE_ID"
fi
echo ""

# Step 4: Run
echo "[4/4] Launching app..."
echo ""

flutter run -d "$DEVICE_ID"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    ✓ Deployment Complete                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
