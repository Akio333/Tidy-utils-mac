import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            TidyWindowBackground()

            NavigationSplitView {
                TidySidebar(selection: $state.selectedSection)
                    .navigationSplitViewColumnWidth(min: 198, ideal: 218, max: 250)
            } detail: {
                selectedView
            }
            .navigationSplitViewStyle(.balanced)
        }
        .tint(TidyTheme.accent)
        .background(MainWindowReader { window in
            state.mainWindow.window = window
            window?.titlebarAppearsTransparent = true
            window?.isMovableByWindowBackground = true
            window?.backgroundColor = .clear
        })
    }

    @ViewBuilder
    private var selectedView: some View {
        switch state.selectedSection {
        case .dashboard:
            DashboardView(monitor: state.monitor, appState: state)
        case .cleaning:
            CleaningView(service: state.cleaner)
        case .displays:
            DisplayView(service: state.display)
        case .mouse:
            MouseView(service: state.mouse)
        }
    }
}

private struct TidySidebar: View {
    @Binding var selection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                SymbolTile(symbol: "sparkles", tint: TidyTheme.accent, size: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Tidy")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Mac utilities")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 42)
            .padding(.horizontal, 18)
            .padding(.bottom, 24)

            VStack(spacing: 7) {
                ForEach(AppSection.allCases) { section in
                    SidebarItem(section: section, isSelected: selection == section) {
                        withAnimation(.snappy(duration: 0.28)) {
                            selection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(TidyTheme.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: TidyTheme.green.opacity(0.6), radius: 4)
                Text("Monitoring active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("0.0.4")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .tidyGlass(cornerRadius: 14, tint: TidyTheme.green)
            .padding(12)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 0.5)
        }
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                    .foregroundStyle(isSelected ? .white : section.tint)
                    .frame(width: 30, height: 30)
                    .background {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(isSelected ? section.tint : section.tint.opacity(0.10))
                    }

                Text(section.title)
                    .font(.callout.weight(isSelected ? .semibold : .medium))

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.thinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.28), lineWidth: 0.7)
                        }
                        .shadow(color: section.tint.opacity(0.12), radius: 8, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                SymbolTile(symbol: symbol, tint: tint, size: 38)
                Spacer()
                Text(value)
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            TidyProgressBar(value: progress, tint: tint)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .leading)
        .tidyGlass(cornerRadius: 20, tint: tint, interactive: true)
    }
}

extension AppSection {
    var tint: Color {
        switch self {
        case .dashboard: TidyTheme.accent
        case .cleaning: TidyTheme.green
        case .displays: TidyTheme.purple
        case .mouse: TidyTheme.orange
        }
    }
}
