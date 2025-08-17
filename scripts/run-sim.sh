#!/usr/bin/env bash
set -euo pipefail

# Run the watchOS app on the latest available watchOS Simulator.

PROJECT="HackerNewsWatch.xcodeproj"
SCHEME="HackerNewsWatch Watch App"
DERIVED_DATA=".derived"

# Ensure project exists
if [ ! -d "$PROJECT" ]; then
  echo "Project not found. Generating with XcodeGen..."
  ./scripts/generate.sh
fi

# Build for simulator (Debug) and capture settings for product path
echo "Building app for watchOS Simulator..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "generic/platform=watchOS Simulator" -derivedDataPath "$DERIVED_DATA" build >/tmp/hnwatch_build.log 2>&1 || {
  cat /tmp/hnwatch_build.log
  exit 1
}

# Get product path from build settings
BUILD_SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "generic/platform=watchOS Simulator" -derivedDataPath "$DERIVED_DATA" -showBuildSettings)
TARGET_BUILD_DIR=$(printf "%s\n" "$BUILD_SETTINGS" | awk -F' = ' '/ TARGET_BUILD_DIR / {print $2; exit}')
WRAPPER_NAME=$(printf "%s\n" "$BUILD_SETTINGS" | awk -F' = ' '/ WRAPPER_NAME / {print $2; exit}')
APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

# Fallback to search if path not found
if [ ! -d "$APP_PATH" ]; then
  # Prefer the local derived data path first
  APP_PATH=$(find "$DERIVED_DATA" -name "$WRAPPER_NAME" -path "*/Build/Products/Debug-watchsimulator/*" -print -quit || true)
fi

if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
  # Fallback to global DerivedData as a last resort
  APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "$WRAPPER_NAME" -path "*/Build/Products/Debug-watchsimulator/*" -print -quit || true)
fi

if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
  echo "Could not locate built .app. Checked: $TARGET_BUILD_DIR/$WRAPPER_NAME"
  exit 1
fi

echo "App path: $APP_PATH"

# Determine bundle identifier from built Info.plist
INFO_PLIST="$APP_PATH/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
  echo "Info.plist not found in app bundle at: $INFO_PLIST"
  exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PLIST" 2>/dev/null || true)
if [ -z "${BUNDLE_ID:-}" ]; then
  # fallback using defaults
  BUNDLE_ID=$(defaults read "${APP_PATH}/Info" CFBundleIdentifier 2>/dev/null || true)
fi
if [ -z "${BUNDLE_ID:-}" ]; then
  echo "Unable to read CFBundleIdentifier from Info.plist"
  exit 1
fi
echo "Bundle ID: $BUNDLE_ID"

# Find latest available watchOS runtime identifier
RUNTIME_LINE=$(xcrun simctl list runtimes | grep -E '^watchOS ' | tail -1 || true)
RUNTIME_ID=$(sed -n 's/.* - \(com\.apple\.CoreSimulator\.SimRuntime\.[^) ]*\).*/\1/p' <<<"${RUNTIME_LINE:-}")
if [ -z "${RUNTIME_ID:-}" ]; then
  echo "No watchOS simulator runtime found. Please install a watchOS simulator in Xcode (Settings > Platforms > watchOS)."
  exit 1
fi
echo "Using runtime: $RUNTIME_ID"

# Pick a recent Apple Watch device type identifier (prefer newer models)
DEVICETYPE_ID=$(xcrun simctl list devicetypes | grep -E 'Apple Watch Series 10 \(46mm\)' | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+' | tail -1)
# Fallbacks
if [ -z "${DEVICETYPE_ID:-}" ]; then
  DEVICETYPE_ID=$(xcrun simctl list devicetypes | grep -E 'Apple Watch Ultra 2 \(49mm\)' | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+' | tail -1)
fi
if [ -z "${DEVICETYPE_ID:-}" ]; then
  DEVICETYPE_ID=$(xcrun simctl list devicetypes | grep -E 'Apple Watch Series 9 \(45mm\)' | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+' | tail -1)
fi
if [ -z "${DEVICETYPE_ID:-}" ]; then
  DEVICETYPE_ID=$(xcrun simctl list devicetypes | grep 'Apple Watch' | grep -oE 'com\.apple\.CoreSimulator\.SimDeviceType\.[^)]+' | tail -1)
fi
if [ -z "${DEVICETYPE_ID:-}" ]; then
  echo "No Apple Watch device types found."
  exit 1
fi
echo "Using device type: $DEVICETYPE_ID"

# Create a fresh simulator to avoid mismatched pairings
DEVICE_NAME="HN Watch $(date +%s)"
echo "Creating simulator: $DEVICE_NAME"
UDID=$(xcrun simctl create "$DEVICE_NAME" "$DEVICETYPE_ID" "$RUNTIME_ID")
if [ -z "${UDID:-}" ]; then
  echo "Failed to create simulator."
  exit 1
fi
echo "Simulator UDID: $UDID"

# Boot and open Simulator
echo "Booting simulator..."
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$UDID"

# Install and launch app
echo "Installing app..."
xcrun simctl install "$UDID" "$APP_PATH"
echo "Launching app ($BUNDLE_ID)..."
xcrun simctl launch "$UDID" "$BUNDLE_ID" || {
  echo "Launch failed. You can open Simulator and launch manually.";
  exit 1;
}

echo "App launched on simulator."
