import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases) { section in
                Button {
                    state.selectedSection = section
                } label: {
                    Label(section.title, systemImage: section.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(state.selectedSection == section ? Color.accentColor.opacity(0.16) : Color.clear)
            }
            .navigationTitle("Tidy")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch state.selectedSection {
                case .dashboard: DashboardView(monitor: state.monitor, appState: state)
                case .cleaning: CleaningView(service: state.cleaner)
                case .displays: DisplayView(service: state.display)
                case .mouse: MouseView(service: state.mouse)
                }
            }
        }
        .tint(.indigo)
        .background(MainWindowReader { window in
            state.mainWindow.window = window
        })
    }
}

private struct MainWindowReader: NSViewRepresentable {
    let onResolve: @MainActor (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(view.window) }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.title2.weight(.semibold))
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    let tint: Color
    let progress: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Image(systemName: symbol).foregroundStyle(tint); Spacer(); Text(value).font(.title3.weight(.semibold)) }
            Text(title).font(.headline)
            ProgressView(value: min(max(progress, 0), 1)).tint(tint)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: 16))
    }
}
