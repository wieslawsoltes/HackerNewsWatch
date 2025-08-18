#!/usr/bin/env bash
set -euo pipefail

# Package the built watchOS app (.app) and its dSYM into zip artifacts for CI distribution.

PROJECT="HackerNewsWatch.xcodeproj"
SCHEME="HackerNewsWatch Watch App"
DERIVED_DATA=".derived"
DESTINATION="generic/platform=watchOS Simulator"
CONFIGURATION="Debug"

# Ensure project exists (generate if missing)
if [ ! -d "$PROJECT" ]; then
  echo "Project not found. Generating with XcodeGen..."
  ./scripts/generate.sh
fi

# Build app (idempotent if already built by previous step)
echo "Building app (if needed)..."
./scripts/build.sh

# Obtain build settings to locate the product path
BUILD_SETTINGS=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA" -showBuildSettings)
TARGET_BUILD_DIR=$(printf "%s\n" "$BUILD_SETTINGS" | awk -F' = ' '/ TARGET_BUILD_DIR / {print $2; exit}')
WRAPPER_NAME=$(printf "%s\n" "$BUILD_SETTINGS" | awk -F' = ' '/ WRAPPER_NAME / {print $2; exit}')
APP_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

# Fallback search in local derived data if path not found
if [ ! -d "$APP_PATH" ]; then
  APP_PATH=$(find "$DERIVED_DATA" -name "$WRAPPER_NAME" -path "*/Build/Products/${CONFIGURATION}-watchsimulator/*" -print -quit || true)
fi
# Fallback search in global DerivedData
if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
  APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "$WRAPPER_NAME" -path "*/Build/Products/${CONFIGURATION}-watchsimulator/*" -print -quit || true)
fi

if [ -z "${APP_PATH:-}" ] || [ ! -d "$APP_PATH" ]; then
  echo "Could not locate built .app. Checked: $TARGET_BUILD_DIR/$WRAPPER_NAME"
  exit 1
fi

echo "App path: $APP_PATH"

ARTIFACTS_DIR="artifacts"
mkdir -p "$ARTIFACTS_DIR"
ROOT_DIR="$(pwd)"

# Create zip for the .app bundle
APP_ZIP="$ARTIFACTS_DIR/HackerNewsWatch_Watch_App_${CONFIGURATION}-watchsimulator.zip"
APP_ZIP_ABS="$ROOT_DIR/$APP_ZIP"
rm -f "$APP_ZIP_ABS"
echo "Creating app archive: $APP_ZIP"
(
  cd "$(dirname "$APP_PATH")"
  zip -9 -r "$APP_ZIP_ABS" "$(basename "$APP_PATH")" >/dev/null
)

# Create zip for dSYM if available
DSYM_PATH="${APP_PATH}.dSYM"
if [ -d "$DSYM_PATH" ]; then
  DSYM_ZIP="$ARTIFACTS_DIR/HackerNewsWatch_Watch_App_${CONFIGURATION}-watchsimulator.dSYM.zip"
  DSYM_ZIP_ABS="$ROOT_DIR/$DSYM_ZIP"
  rm -f "$DSYM_ZIP_ABS"
  echo "Creating dSYM archive: $DSYM_ZIP"
  (
    cd "$(dirname "$DSYM_PATH")"
    zip -9 -r "$DSYM_ZIP_ABS" "$(basename "$DSYM_PATH")" >/dev/null
  )
else
  echo "dSYM not found at $DSYM_PATH (skipping)"
fi

echo "Artifacts ready in: $ARTIFACTS_DIR"
ls -l "$ARTIFACTS_DIR"