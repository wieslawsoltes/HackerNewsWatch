#!/usr/bin/env bash
set -euo pipefail

# Generate the Xcode project via XcodeGen (force fresh regeneration)

command -v xcodegen >/dev/null 2>&1 || {
  echo "XcodeGen not found. Installing via Homebrew...";
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew or XcodeGen manually.";
    exit 1;
  fi
  brew install xcodegen
}


# Remove existing project to avoid stale file references (e.g., deleted sources)
if [ -d "HackerNewsWatch.xcodeproj" ]; then
  echo "Removing existing Xcode project..."
  rm -rf "HackerNewsWatch.xcodeproj"
fi

# Regenerate without cache so file list reflects current Sources/
xcodegen generate --spec project.yml

echo "Generated HackerNewsWatch.xcodeproj"
