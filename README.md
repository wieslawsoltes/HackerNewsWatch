# HackerNewsWatch (watchOS)

A minimal Hacker News reader for Apple Watch built with SwiftUI.

- Scrollable top stories feed with title, points, and comments count
- Tap a story to view comments in a simple tree-style view
- "Open Article" link at the top opens the article in the watch browser
- HN-like styling (orange accent)

<img width="580" height="612" alt="image" src="https://github.com/user-attachments/assets/100cdb20-bbbc-404f-8790-566939c3acfe" />


## Requirements
- Xcode 15 or newer
- macOS with command line tools
- Homebrew (for XcodeGen) or install XcodeGen manually

## Generate the Xcode project

```bash
./scripts/generate.sh
```

This will install XcodeGen if needed and generate `HackerNewsWatch.xcodeproj`.

## Build

```bash
./scripts/build.sh
```

- To run on the latest available watchOS Simulator and auto-launch the app:

```bash
./scripts/run-sim.sh
```

- The script will pick a recent Apple Watch simulator runtime and boot it. You can also open the generated `HackerNewsWatch.xcodeproj` in Xcode and run there.

## Project layout
- `project.yml` – XcodeGen spec
- `Sources/WatchApp` – Swift sources for the watch app
- `scripts/` – helper scripts to generate and build

## Privacy
The app accesses the public Hacker News API over HTTPS and does not collect or store personal data.

## License
MIT
