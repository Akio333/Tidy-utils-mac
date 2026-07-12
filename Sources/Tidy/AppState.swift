import SwiftUI
import ServiceManagement

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSection: AppSection = .dashboard
    @Published private(set) var keepInMenuBarWhenWindowCloses: Bool
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    @Published private(set) var launchAtLoginStatus = ""
    let mainWindow = MainWindowPresenter()
    let cleaner = CleanerService()
    let display = DisplayService()
    let mouse = MouseService()
    let monitor = SystemMonitor()
    let statusMonitor = SystemMonitor()

    init() {
        keepInMenuBarWhenWindowCloses = UserDefaults.standard.object(forKey: "keepInMenuBarWhenWindowCloses") as? Bool ?? true
        mainWindow.closeHandler = { [weak self] in self?.handleWindowClose() }
        monitor.start(interval: 1)
        statusMonitor.start(interval: 5)
    }

    func setKeepInMenuBarWhenWindowCloses(_ enabled: Bool) {
        keepInMenuBarWhenWindowCloses = enabled
        UserDefaults.standard.set(enabled, forKey: "keepInMenuBarWhenWindowCloses")
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginStatus = launchAtLogin == enabled ? "" : "macOS did not update the login item."
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            launchAtLoginStatus = "Could not update launch at login: \(error.localizedDescription)"
        }
    }

    private func handleWindowClose() {
        if keepInMenuBarWhenWindowCloses {
            mainWindow.hide()
        } else {
            NSApplication.shared.terminate(nil)
        }
    }
}

@MainActor
final class MainWindowPresenter: NSObject {
    var closeHandler: (() -> Void)?
    var window: NSWindow? {
        didSet {
            guard oldValue !== window else { return }
            window?.isReleasedWhenClosed = false
            let button = window?.standardWindowButton(.closeButton)
            button?.target = self
            button?.action = #selector(closeButtonPressed(_:))
        }
    }

    func show() {
        guard let window else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    @objc private func closeButtonPressed(_ sender: Any?) {
        closeHandler?()
    }

}
