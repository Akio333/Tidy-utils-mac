# Tidy

A native SwiftUI macOS utility that brings cleaning, display controls, pointer preferences, and a compact system monitor together.

Current version: **0.0.1**

Tidy is a hobby project built primarily for personal use. It is under active development, and contributions of all kinds are welcome—bug reports, feature ideas, documentation, design feedback, and code.

## Run

Open `Tidy.xcodeproj` in Xcode and run the `Tidy` app scheme. This target builds a real `Tidy.app` with the bundle identifier `com.akio.Tidy`.

For command-line development, `swift run` remains available on macOS.

## Design notes

- Cleaning scans user cache, logs, Trash, and Homebrew-cache locations and always shows targets before removal.
- Display modes use CoreGraphics. DDC brightness and volume call a locally installed `ddcutil` executable when available.
- Hardware behaviours that macOS prevents ordinary apps from changing (built-in panel disable and per-device event interception) are deliberately surfaced as persisted preferences with clear capability notes. A future privileged/accessibility helper can apply them.

## Contributing

Contributions are welcome. Please open an issue or pull request with a clear description of the problem or proposed improvement. Because Tidy can remove files and change system preferences, changes to those areas should favor safety, explicit user confirmation, and reversible behavior wherever possible.

## License

Tidy is licensed under the [GNU General Public License version 2](LICENSE).
