import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedSection: AppSection = .dashboard
    let mainWindow = MainWindowPresenter()
    let cleaner = CleanerService()
    let display = DisplayService()
    let mouse = MouseService()
    let monitor = SystemMonitor()
    let statusMonitor = SystemMonitor()

    init() {
        monitor.start(interval: 1)
        statusMonitor.start(interval: 5)
    }
}

@MainActor
final class MainWindowPresenter {
    var window: NSWindow? {
        didSet {
            guard oldValue !== window else { return }
            window?.isReleasedWhenClosed = false
        }
    }

    func show() {
        guard let window else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
    }

}
