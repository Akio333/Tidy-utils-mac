# Tidy

A native SwiftUI macOS utility that brings cleaning, display controls, pointer preferences, and a compact system monitor together.

Current version: **0.0.2**

Tidy is a hobby project built primarily for personal use. It is under active development, and contributions of all kinds are welcome—bug reports, feature ideas, documentation, design feedback, and code.

## Run

Open `Tidy.xcodeproj` in Xcode and run the `Tidy` app scheme. This target builds a real `Tidy.app` with the bundle identifier `com.akio.Tidy`.

For command-line development, `swift run` remains available on macOS.

## Distribution and Gatekeeper

Release builds are packaged as a `Tidy-macos.dmg` containing `Tidy.app` and an Applications-folder shortcut. A DMG is friendlier to install, but it does **not** by itself make an app trusted by macOS.

To distribute without Gatekeeper's “Apple could not verify” warning, the release app must be signed with a paid Apple Developer Program **Developer ID Application** certificate and notarized by Apple. The required release sequence is:

1. Archive and sign `Tidy.app` with Developer ID and the hardened runtime.
2. Submit the signed app or DMG through `xcrun notarytool submit --wait` using Apple Developer credentials.
3. Staple the notarization ticket with `xcrun stapler staple Tidy.app` (or the DMG).

For a personal, unsigned build, macOS can open it through Finder’s Control-click → Open flow. This is a local exception only; it is not a replacement for signing and notarization when sharing the app.

To package a locally built app as a DMG:

```sh
./Scripts/package-dmg.sh .build/xcode/Build/Products/Release/Tidy.app artifact/Tidy-macos.dmg "Tidy 0.0.2"
```

## Design notes

- Cleaning scans user cache, logs, Trash, and Homebrew-cache locations and always shows targets before removal.
- Display modes use CoreGraphics. DDC brightness and volume call a locally installed `ddcutil` executable when available.
- Hardware behaviours that macOS prevents ordinary apps from changing (built-in panel disable and per-device event interception) are deliberately surfaced as persisted preferences with clear capability notes. A future privileged/accessibility helper can apply them.

## Contributing

Contributions are welcome. Please open an issue or pull request with a clear description of the problem or proposed improvement. Because Tidy can remove files and change system preferences, changes to those areas should favor safety, explicit user confirmation, and reversible behavior wherever possible.

## License

Tidy is licensed under the [GNU General Public License version 2](LICENSE).
