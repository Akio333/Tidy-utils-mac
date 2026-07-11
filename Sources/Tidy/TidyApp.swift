import SwiftUI

@main
struct TidyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        Window("Tidy", id: "main") {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 980, minHeight: 650)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh system status") {
                    appState.monitor.refresh()
                    appState.statusMonitor.refresh()
                }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            StatusMenu(monitor: appState.statusMonitor)
                .environmentObject(appState)
        } label: {
            StatusLabel(monitor: appState.statusMonitor)
        }
        .menuBarExtraStyle(.window)
    }
}
