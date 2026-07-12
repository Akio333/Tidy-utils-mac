import SwiftUI

struct DashboardView: View {
    @ObservedObject var monitor: SystemMonitor
    private var snapshot: SystemSnapshot { monitor.snapshot }
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 26) {
            SectionHeader(title: "Overview", subtitle: "Current system status")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                MetricCard(title: "CPU", value: "\(Int(snapshot.cpuPercent))%", detail: "Current processor load", symbol: "cpu", tint: .blue, progress: snapshot.cpuPercent / 100)
                MetricCard(title: "CPU temperature", value: snapshot.cpuTemperatureAvailable ? snapshot.cpuTemperatureText : "—", detail: snapshot.cpuTemperatureAvailable ? "Current die temperature" : "Sensor unavailable", symbol: "thermometer.medium", tint: .red, progress: snapshot.cpuTemperature / 100)
                MetricCard(title: "Memory", value: "\(Int(snapshot.memoryPercent))%", detail: "\(snapshot.memoryUsed.tidySize) in use", symbol: "memorychip", tint: .purple, progress: snapshot.memoryPercent / 100)
                MetricCard(title: "Storage", value: "\(Int(snapshot.diskPercent))%", detail: "\(snapshot.diskUsed.tidySize) used", symbol: "internaldrive", tint: .orange, progress: snapshot.diskPercent / 100)
            }
            GroupBox("Activity") { HStack(spacing: 24) { UsageChart(values: snapshot.cpuHistory, color: .blue, title: "CPU"); UsageChart(values: snapshot.cpuTemperatureHistory, color: .red, title: "CPU temperature"); UsageChart(values: snapshot.memoryHistory, color: .purple, title: "Memory") }.padding(8) }
            HStack { Label(snapshot.gpuName, systemImage: "rectangle.inset.filled.and.person.filled").foregroundStyle(.secondary); Spacer(); Text("Updates every second").font(.caption).foregroundStyle(.tertiary); Button("Refresh") { monitor.refresh() }.buttonStyle(.bordered) }
        }.padding(28) }.background(Color(nsColor: .windowBackgroundColor))
    }
}

struct UsageChart: View {
    let values: [Double]; let color: Color; let title: String
    var body: some View { VStack(alignment: .leading) { Text(title).font(.headline); GeometryReader { proxy in
        Path { path in for (index, value) in values.enumerated() { let point = CGPoint(x: proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1)), y: proxy.size.height * (1 - CGFloat(value / 100))); index == 0 ? path.move(to: point) : path.addLine(to: point) } }.stroke(color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
    }.frame(height: 90) }.frame(maxWidth: .infinity, alignment: .leading) }
}
