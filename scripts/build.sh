#!/usr/bin/env bash
set -euo pipefail

# Build the watchOS app in Debug for a simulator

PROJECT="HackerNewsWatch.xcodeproj"
SCHEME="HackerNewsWatch Watch App"
DESTINATION="generic/platform=watchOS Simulator"
DERIVED_DATA=".derived"

if [ ! -d "$PROJECT" ]; then
  echo "Project not found. Generating with XcodeGen..."
  ./scripts/generate.sh
fi

mkdir -p "$DERIVED_DATA"

if command -v xcpretty >/dev/null 2>&1; then
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -sdk watchsimulator -configuration Debug -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA" clean build | xcpretty
else
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -sdk watchsimulator -configuration Debug -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA" clean build
fi
