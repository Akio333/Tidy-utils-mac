import SwiftUI

@main
struct TidyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 980, minHeight: 650)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh system status") { appState.monitor.refresh() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            StatusMenu()
                .environmentObject(appState)
        } label: {
            StatusLabel(snapshot: appState.monitor.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
