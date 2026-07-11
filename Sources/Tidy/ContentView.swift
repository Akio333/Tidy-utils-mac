import SwiftUI

struct ContentView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Tidy")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection ?? .dashboard {
                case .dashboard: DashboardView()
                case .cleaning: CleaningView()
                case .displays: DisplayView()
                case .mouse: MouseView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text((selection ?? .dashboard).title).font(.headline)
                }
            }
        }
        .tint(.indigo)
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
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
