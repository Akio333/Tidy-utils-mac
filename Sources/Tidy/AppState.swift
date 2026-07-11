import SwiftUI

@MainActor
final class AppState: ObservableObject {
    let cleaner = CleanerService()
    let display = DisplayService()
    let mouse = MouseService()
    let monitor = SystemMonitor()

    init() {
        monitor.start()
    }
}
