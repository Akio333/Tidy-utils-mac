import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitor: SystemMonitor
    @ObservedObject var appState: AppState
    private var snapshot: SystemSnapshot { monitor.snapshot }

    private let metricColumns = [GridItem(.adaptive(minimum: 175), spacing: 14)]
    private let chartColumns = [GridItem(.adaptive(minimum: 260), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center) {
                    PageHeader(
                        title: "Overview",
                        subtitle: "A live view of your Mac’s performance.",
                        symbol: "waveform.path.ecg",
                        tint: TidyTheme.accent
                    )

                    Spacer()

                    StatusCapsule(text: "Live · 1 sec", symbol: "dot.radiowaves.left.and.right")
                    Button {
                        monitor.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .help("Refresh now")
                }

                LazyVGrid(columns: metricColumns, spacing: 14) {
                    MetricCard(
                        title: "CPU",
                        value: "\(Int(snapshot.cpuPercent))%",
                        detail: "Current processor load",
                        symbol: "cpu",
                        tint: TidyTheme.cyan,
                        progress: snapshot.cpuPercent / 100
                    )
                    MetricCard(
                        title: "Temperature",
                        value: snapshot.cpuTemperatureAvailable ? snapshot.cpuTemperatureText : "—",
                        detail: snapshot.cpuTemperatureAvailable ? "Current CPU die" : "Sensor unavailable",
                        symbol: "thermometer.medium",
                        tint: TidyTheme.red,
                        progress: snapshot.cpuTemperature / 100
                    )
                    MetricCard(
                        title: "Memory",
                        value: "\(Int(snapshot.memoryPercent))%",
                        detail: "\(snapshot.memoryUsed.tidySize) in use",
                        symbol: "memorychip",
                        tint: TidyTheme.purple,
                        progress: snapshot.memoryPercent / 100
                    )
                    MetricCard(
                        title: "Storage",
                        value: "\(Int(snapshot.diskPercent))%",
                        detail: "\(snapshot.diskUsed.tidySize) used",
                        symbol: "internaldrive",
                        tint: TidyTheme.orange,
                        progress: snapshot.diskPercent / 100
                    )
                }

                GlassSection(
                    title: "Live activity",
                    subtitle: "The last 30 seconds",
                    symbol: "chart.xyaxis.line",
                    tint: TidyTheme.accent
                ) {
                    LazyVGrid(columns: chartColumns, spacing: 14) {
                        UsageChart(
                            values: snapshot.cpuHistory,
                            color: TidyTheme.cyan,
                            title: "CPU",
                            value: "\(Int(snapshot.cpuPercent))%"
                        )
                        UsageChart(
                            values: snapshot.cpuTemperatureHistory,
                            color: TidyTheme.red,
                            title: "CPU temperature",
                            value: snapshot.cpuTemperatureText
                        )
                        UsageChart(
                            values: snapshot.memoryHistory,
                            color: TidyTheme.purple,
                            title: "Memory",
                            value: "\(Int(snapshot.memoryPercent))%"
                        )
                        UsageChart(
                            values: snapshot.gpuHistory,
                            color: TidyTheme.orange,
                            title: "GPU",
                            value: snapshot.gpuUsageAvailable ? "\(Int(snapshot.gpuPercent))%" : "Unavailable"
                        )
                    }
                }

                GlassSection(
                    title: "App behavior",
                    subtitle: "Choose how Tidy runs in the background.",
                    symbol: "gearshape.2",
                    tint: TidyTheme.purple
                ) {
                    VStack(spacing: 0) {
                        SettingRow(
                            title: "Keep Tidy in the menu bar",
                            detail: "Closing the window keeps monitoring active.",
                            symbol: "menubar.rectangle",
                            tint: TidyTheme.accent
                        ) {
                            Toggle("", isOn: closeBehaviorBinding)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        Divider().padding(.leading, 43).padding(.vertical, 13)

                        SettingRow(
                            title: "Launch at login",
                            detail: "Start monitoring when you sign in to your Mac.",
                            symbol: "power",
                            tint: TidyTheme.green
                        ) {
                            Toggle("", isOn: launchAtLoginBinding)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        if !appState.launchAtLoginStatus.isEmpty {
                            Text(appState.launchAtLoginStatus)
                                .font(.caption)
                                .foregroundStyle(TidyTheme.orange)
                                .padding(.top, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                    Text(snapshot.gpuName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            }
            .padding(28)
            .frame(maxWidth: 1180, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(Color.clear)
    }

    private var closeBehaviorBinding: Binding<Bool> {
        Binding(
            get: { appState.keepInMenuBarWhenWindowCloses },
            set: { value in appState.setKeepInMenuBarWhenWindowCloses(value) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLogin },
            set: { value in appState.setLaunchAtLogin(value) }
        )
    }
}

struct UsageChart: View {
    let values: [Double]
    let color: Color
    let title: String
    var value: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: chartSymbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let value {
                    Text(value)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .contentTransition(.numericText())
                }
            }

            GeometryReader { proxy in
                ZStack {
                    VStack {
                        ForEach(0..<3, id: \.self) { _ in
                            Divider().opacity(0.38)
                            Spacer()
                        }
                    }

                    chartFill(in: proxy.size)
                    chartLine(in: proxy.size)
                }
            }
            .frame(height: 92)
        }
        .padding(15)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
        }
    }

    private var chartSymbol: String {
        switch title {
        case "CPU temperature": "thermometer.medium"
        case "Memory": "memorychip"
        case "GPU": "square.stack.3d.up"
        default: "cpu"
        }
    }

    private func chartLine(in size: CGSize) -> some View {
        chartPath(in: size)
            .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            .shadow(color: color.opacity(0.35), radius: 4)
    }

    private func chartFill(in size: CGSize) -> some View {
        var path = chartPath(in: size)
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path.fill(
            LinearGradient(
                colors: [color.opacity(0.24), color.opacity(0.01)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func chartPath(in size: CGSize) -> Path {
        Path { path in
            for (index, value) in values.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                let y = size.height * (1 - CGFloat(min(max(value, 0), 100) / 100))
                let point = CGPoint(x: x, y: y)
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
        }
    }
}
