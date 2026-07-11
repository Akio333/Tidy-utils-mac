# Tidy

A native SwiftUI macOS utility that brings cleaning, display controls, pointer preferences, and a compact system monitor together.

## Run

Open the folder in Xcode and run the `Tidy` executable target, or use `swift run` on macOS.

## Design notes

- Cleaning scans user cache, logs, Trash, and Homebrew-cache locations and always shows targets before removal.
- Display modes use CoreGraphics. DDC brightness and volume call a locally installed `ddcutil` executable when available.
- Hardware behaviours that macOS prevents ordinary apps from changing (built-in panel disable and per-device event interception) are deliberately surfaced as persisted preferences with clear capability notes. A future privileged/accessibility helper can apply them.
