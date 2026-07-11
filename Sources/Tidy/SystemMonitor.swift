import Foundation
import AppKit
import SwiftUI

@MainActor
final class SystemMonitor: ObservableObject {
    @Published private(set) var snapshot = SystemSnapshot()
    private var timer: Timer?
    private var previousCPU: host_cpu_load_info = host_cpu_load_info()
    private var hasPreviousCPU = false

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        let cpu = cpuUsage()
        let memory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = activeMemory() + wiredMemory()
        let disk = (try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())) ?? [:]
        let usedDisk = (disk[.systemSize] as? NSNumber)?.uint64Value ?? 0
        let totalDisk = (disk[.systemFreeSize] as? NSNumber).map { usedDisk + $0.uint64Value } ?? 0
        snapshot.cpuPercent = cpu
        snapshot.memoryUsed = usedMemory
        snapshot.memoryTotal = memory
        snapshot.diskUsed = usedDisk
        snapshot.diskTotal = totalDisk
        snapshot.gpuName = graphicsName()
        snapshot.cpuHistory = Array((snapshot.cpuHistory + [cpu]).suffix(30))
        snapshot.memoryHistory = Array((snapshot.memoryHistory + [snapshot.memoryPercent]).suffix(30))
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
        return "Apple GPU"
    }
}

struct StatusLabel: View {
    let snapshot: SystemSnapshot
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")
            Text("\(Int(snapshot.cpuPercent))%")
                .monospacedDigit()
        }
    }
}

struct StatusMenu: View {
    @EnvironmentObject private var state: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tidy Monitor").font(.headline)
            HStack { Text("CPU"); Spacer(); Text("\(Int(state.monitor.snapshot.cpuPercent))%") }
            HStack { Text("Memory"); Spacer(); Text("\(state.monitor.snapshot.memoryUsed.tidySize) of \(state.monitor.snapshot.memoryTotal.tidySize)") }
            Button("Refresh now") { state.monitor.refresh() }
            Divider()
            Button("Quit Tidy") { NSApplication.shared.terminate(nil) }
        }.padding().frame(width: 270)
    }
}
