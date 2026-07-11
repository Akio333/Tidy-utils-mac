import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard, cleaning, displays, mouse

    var id: String { rawValue }
    var title: String {
        switch self {
        case .dashboard: "Overview"
        case .cleaning: "Cleaning"
        case .displays: "Displays"
        case .mouse: "Mouse"
        }
    }
    var icon: String {
        switch self {
        case .dashboard: "waveform.path.ecg"
        case .cleaning: "sparkles"
        case .displays: "display.2"
        case .mouse: "computermouse"
        }
    }
}

struct CleanableItem: Identifiable, Hashable {
    let id: URL
    let name: String
    let location: String
    let category: String
    let url: URL
    let size: Int64
    var selected: Bool = true
}

struct DisplayInfo: Identifiable, Hashable {
    let id: UInt32
    let name: String
    let isBuiltIn: Bool
    let width: Int
    let height: Int
}

struct SystemSnapshot {
    var cpuPercent: Double = 0
    var gpuPercent: Double = 0
    var gpuUsageAvailable = false
    var memoryUsed: UInt64 = 0
    var memoryTotal: UInt64 = 0
    var diskUsed: UInt64 = 0
    var diskTotal: UInt64 = 0
    var gpuName = "Integrated GPU"
    var cpuHistory: [Double] = Array(repeating: 0, count: 30)
    var memoryHistory: [Double] = Array(repeating: 0, count: 30)
    var gpuHistory: [Double] = Array(repeating: 0, count: 30)

    var memoryPercent: Double { memoryTotal == 0 ? 0 : Double(memoryUsed) / Double(memoryTotal) * 100 }
    var diskPercent: Double { diskTotal == 0 ? 0 : Double(diskUsed) / Double(diskTotal) * 100 }
}

extension Int64 {
    var tidySize: String { ByteCountFormatter.string(fromByteCount: self, countStyle: .file) }
}

extension UInt64 {
    var tidySize: String { ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file) }
}
