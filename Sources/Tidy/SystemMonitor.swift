import Foundation
import AppKit
import SwiftUI
import IOKit
import Metal
#if SWIFT_PACKAGE
import TidyTemperatureReader
#endif

@MainActor
final class SystemMonitor: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot()
    private var timer: Timer?
    private var previousCPU: host_cpu_load_info = host_cpu_load_info()
    private var hasPreviousCPU = false

    func start(interval: TimeInterval) {
        timer?.invalidate()
        refresh()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func refresh() {
        let cpu = cpuUsage()
        let memory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = activeMemory() + wiredMemory()
        let disk = (try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())) ?? [:]
        let totalDisk = (disk[.systemSize] as? NSNumber)?.uint64Value ?? 0
        let freeDisk = (disk[.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
        let usedDisk = totalDisk > freeDisk ? totalDisk - freeDisk : 0
        let gpu = gpuUsage()
        let temperature = cpuTemperature()
        snapshot.cpuPercent = cpu
        snapshot.memoryUsed = usedMemory
        snapshot.memoryTotal = memory
        snapshot.diskUsed = usedDisk
        snapshot.diskTotal = totalDisk
        snapshot.gpuName = graphicsName()
        snapshot.gpuPercent = gpu.value
        snapshot.gpuUsageAvailable = gpu.available
        snapshot.cpuTemperature = temperature ?? 0
        snapshot.cpuTemperatureAvailable = temperature != nil
        snapshot.cpuHistory = Array((snapshot.cpuHistory + [cpu]).suffix(30))
        snapshot.cpuTemperatureHistory = Array((snapshot.cpuTemperatureHistory + [temperature ?? 0]).suffix(30))
        snapshot.memoryHistory = Array((snapshot.memoryHistory + [snapshot.memoryPercent]).suffix(30))
        snapshot.gpuHistory = Array((snapshot.gpuHistory + [gpu.value]).suffix(30))
    }

    private func cpuUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        defer { previousCPU = info; hasPreviousCPU = true }
        guard hasPreviousCPU else { return 0 }
        let user = info.cpu_ticks.0 - previousCPU.cpu_ticks.0
        let system = info.cpu_ticks.1 - previousCPU.cpu_ticks.1
        let idle = info.cpu_ticks.2 - previousCPU.cpu_ticks.2
        let nice = info.cpu_ticks.3 - previousCPU.cpu_ticks.3
        let total = user + system + idle + nice
        return total == 0 ? 0 : Double(user + system + nice) / Double(total) * 100
    }

    private func activeMemory() -> UInt64 { vmStat(named: "Pages active") }
    private func wiredMemory() -> UInt64 { vmStat(named: "Pages wired down") }
    private func vmStat(named key: String) -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count) } }
        guard result == KERN_SUCCESS else { return 0 }
        let pageSize = UInt64(getpagesize())
        switch key { case "Pages active": return UInt64(stats.active_count) * pageSize; default: return UInt64(stats.wire_count) * pageSize }
    }

    private func graphicsName() -> String {
        MTLCreateSystemDefaultDevice()?.name ?? "GPU"
    }

    private func gpuUsage() -> (value: Double, available: Bool) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return (0, false)
        }
        defer { IOObjectRelease(iterator) }

        var readings: [Double] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            if let property = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue(),
               let statistics = property as? [String: Any] {
                for key in ["Device Utilization %", "GPU Activity(%)", "GPU Core Utilization"] {
                    if let number = statistics[key] as? NSNumber {
                        readings.append(number.doubleValue)
                        break
                    }
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        guard let value = readings.max() else { return (0, false) }
        return (min(max(value, 0), 100), true)
    }

    private func cpuTemperature() -> Double? {
        let value = TidyCPUTemperature()
        return (0...130).contains(value) ? value : nil
    }
}

struct StatusLabel: View {
    @ObservedObject var monitor: SystemMonitor
    private var snapshot: SystemSnapshot { monitor.snapshot }
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(TidyTheme.accent)
            Text("\(Int(snapshot.cpuPercent))%")
                .monospacedDigit()
        }
        .help("CPU \(Int(snapshot.cpuPercent))% · Memory \(Int(snapshot.memoryPercent))%")
    }
}

struct StatusMenu: View {
    @EnvironmentObject private var state: AppState
    @ObservedObject var monitor: SystemMonitor
    private var snapshot: SystemSnapshot { monitor.snapshot }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 11) {
                    SymbolTile(symbol: "waveform.path.ecg", tint: TidyTheme.accent, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tidy Monitor")
                            .font(.headline)
                        Text("Updated every 5 seconds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button { monitor.refresh() } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 28, height: 28)
                }
                    .buttonStyle(.borderless)
                    .help("Refresh now")
            }

            HStack(spacing: 10) {
                PopupMetric(title: "CPU", value: "\(Int(snapshot.cpuPercent))%", symbol: "cpu", tint: TidyTheme.cyan)
                PopupMetric(title: "Memory", value: "\(Int(snapshot.memoryPercent))%", symbol: "memorychip", tint: TidyTheme.purple)
                PopupMetric(title: "Temp", value: snapshot.cpuTemperatureAvailable ? snapshot.cpuTemperatureText : "—", symbol: "thermometer.medium", tint: TidyTheme.red)
            }

            HStack(spacing: 10) {
                UsageChart(values: snapshot.cpuHistory, color: TidyTheme.cyan, title: "CPU", value: "\(Int(snapshot.cpuPercent))%")
                UsageChart(values: snapshot.memoryHistory, color: TidyTheme.purple, title: "Memory", value: "\(Int(snapshot.memoryPercent))%")
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                statusRow("CPU temperature", icon: "thermometer.medium", value: snapshot.cpuTemperatureText)
                statusRow("Memory", icon: "memorychip", value: "\(snapshot.memoryUsed.tidySize) of \(snapshot.memoryTotal.tidySize)")
                statusRow("GPU", icon: "square.stack.3d.up.fill", value: snapshot.gpuUsageAvailable ? "\(Int(snapshot.gpuPercent))% · \(snapshot.gpuName)" : "Unavailable · \(snapshot.gpuName)")
                statusRow("Storage", icon: "internaldrive", value: "\(snapshot.diskUsed.tidySize) of \(snapshot.diskTotal.tidySize)")
            }
            .padding(14)
            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Divider()

            Text("OPEN TIDY")
                .font(.caption2.weight(.semibold))
                .tracking(0.7)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                destinationButton(.dashboard)
                destinationButton(.cleaning)
                destinationButton(.displays)
                destinationButton(.mouse)
            }

            Divider()
            Button("Quit Tidy") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 460)
    }

    @ViewBuilder
    private func statusRow(_ title: String, icon: String, value: String) -> some View {
        GridRow {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 18)
            Text(title)
            Text(value).monospacedDigit().foregroundStyle(.secondary).gridColumnAlignment(.trailing)
        }
    }

    private func destinationButton(_ section: AppSection) -> some View {
        Button {
            state.selectedSection = section
            // Let the MenuBarExtra popover finish dismissing before activating
            // the regular app window. Activating it synchronously makes macOS
            // briefly show and then hide it with the transient popover.
            for delay in [0.15, 0.4] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    state.mainWindow.show()
                }
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundStyle(section.tint)
                Text(section.title).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
        }
        .buttonStyle(.bordered)
        .tint(section.tint)
    }
}

private struct PopupMetric: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption2).foregroundStyle(.secondary)
                Text(value).font(.caption.weight(.semibold).monospacedDigit())
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.7)
        }
    }
}
