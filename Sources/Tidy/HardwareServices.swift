import Foundation
import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class DisplayService: ObservableObject {
    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedDisplayID: UInt32?
    @Published var status = ""
    @Published var turnOffInternalDisplay = UserDefaults.standard.bool(forKey: "turnOffInternalDisplay") { didSet { UserDefaults.standard.set(turnOffInternalDisplay, forKey: "turnOffInternalDisplay") } }
    @Published var brightness = UserDefaults.standard.object(forKey: "externalBrightness") as? Double ?? 70 { didSet { UserDefaults.standard.set(brightness, forKey: "externalBrightness") } }
    @Published var volume = UserDefaults.standard.object(forKey: "externalVolume") as? Double ?? 50 { didSet { UserDefaults.standard.set(volume, forKey: "externalVolume") } }

    init() { refresh() }
    func refresh() {
        var online = [CGDirectDisplayID](repeating: 0, count: 16); var count: UInt32 = 0
        CGGetOnlineDisplayList(UInt32(online.count), &online, &count)
        displays = online.prefix(Int(count)).map { id in
            DisplayInfo(id: id, name: CGDisplayIsBuiltin(id) != 0 ? "Built-in display" : "External display", isBuiltIn: CGDisplayIsBuiltin(id) != 0, width: CGDisplayPixelsWide(id), height: CGDisplayPixelsHigh(id))
        }
        if selectedDisplayID == nil { selectedDisplayID = displays.first(where: { !$0.isBuiltIn })?.id ?? displays.first?.id }
        status = displays.isEmpty ? "No displays detected." : "\(displays.count) display\(displays.count == 1 ? "" : "s") detected."
    }
    func setBrightness() { runDDC(["setvcp", "10", "\(Int(brightness))"]) }
    func setVolume() { runDDC(["setvcp", "62", "\(Int(volume))"]) }
    func availableModes() -> [CGDisplayMode] {
        guard let id = selectedDisplayID, let modes = CGDisplayCopyAllDisplayModes(id, nil) as? [CGDisplayMode] else { return [] }
        return modes.filter { $0.width > 0 && $0.height > 0 }.sorted { $0.width * $0.height > $1.width * $1.height }
    }
    func applyDisplayMode(_ mode: CGDisplayMode) {
        guard let id = selectedDisplayID else { return }
        let result = CGDisplaySetDisplayMode(id, mode, nil)
        status = result == .success ? "Resolution applied." : "macOS rejected this display mode (error \(result.rawValue))."
    }
    private func runDDC(_ arguments: [String]) {
        let path = ["/opt/homebrew/bin/ddcutil", "/usr/local/bin/ddcutil"].first { FileManager.default.isExecutableFile(atPath: $0) }
        guard let path else { status = "Install ddcutil (brew install ddcutil) to control this monitor."; return }
        let process = Process(); process.executableURL = URL(filePath: path); process.arguments = arguments
        let pipe = Pipe(); process.standardError = pipe; process.standardOutput = pipe
        do { try process.run(); process.waitUntilExit(); status = process.terminationStatus == 0 ? "Monitor setting applied." : String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "ddcutil failed." }
        catch { status = "Unable to run ddcutil: \(error.localizedDescription)" }
    }
}

@MainActor
final class MouseService: ObservableObject {
    @Published var trackpadNaturalScrolling = UserDefaults.standard.object(forKey: "trackpadNaturalScrolling") as? Bool ?? true { didSet { UserDefaults.standard.set(trackpadNaturalScrolling, forKey: "trackpadNaturalScrolling") } }
    @Published var mouseNaturalScrolling = UserDefaults.standard.bool(forKey: "mouseNaturalScrolling") { didSet { UserDefaults.standard.set(mouseNaturalScrolling, forKey: "mouseNaturalScrolling") } }
    @Published var disableAcceleration = UserDefaults.standard.bool(forKey: "disableMouseAcceleration") { didSet { UserDefaults.standard.set(disableAcceleration, forKey: "disableMouseAcceleration") } }
    @Published var extraButtonAction = UserDefaults.standard.string(forKey: "extraButtonAction") ?? "Back / Forward" { didSet { UserDefaults.standard.set(extraButtonAction, forKey: "extraButtonAction") } }
    @Published var status = "Settings are saved locally."
    func applyAcceleration() {
        let process = Process(); process.executableURL = URL(filePath: "/usr/bin/defaults")
        process.arguments = ["write", ".GlobalPreferences", "com.apple.mouse.scaling", "-float", disableAcceleration ? "-1" : "0"]
        do { try process.run(); process.waitUntilExit(); status = "Mouse acceleration updated. Reconnect the mouse if it doesn’t apply immediately." }
        catch { status = "Couldn’t apply acceleration: \(error.localizedDescription)" }
    }
}
