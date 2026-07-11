import Foundation

@MainActor
final class CleanerService: ObservableObject {
    @Published private(set) var items: [CleanableItem] = []
    @Published private(set) var isScanning = false
    @Published var status = "Scan for reclaimable files when you’re ready."

    func scan() {
        isScanning = true
        status = "Scanning common cache locations…"
        let paths: [(String, String, URL)] = [
            ("Application caches", "Caches", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Caches")),
            ("Application logs", "Logs", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs")),
            ("Trash", "Trash", FileManager.default.homeDirectoryForCurrentUser.appending(path: ".Trash")),
            ("Homebrew cache", "Homebrew", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Caches/Homebrew"))
        ]
        Task.detached { [paths] in
            let manager = FileManager.default
            let result = paths.compactMap { name, category, url -> CleanableItem? in
                guard manager.fileExists(atPath: url.path) else { return nil }
                let size = Self.directorySize(url, manager: manager)
                return CleanableItem(id: url, name: name, location: url.path, category: category, url: url, size: size)
            }
            await MainActor.run {
                self.items = result
                self.isScanning = false
                self.status = result.isEmpty ? "Nothing obvious to clean." : "Found \(result.map(\.size).reduce(0, +).tidySize) available to review."
            }
        }
    }

    func toggle(_ item: CleanableItem) {
        guard let index = items.firstIndex(of: item) else { return }
        items[index].selected.toggle()
    }

    func cleanSelected() {
        let targets = items.filter(\.selected)
        guard !targets.isEmpty else { status = "Select one or more locations first."; return }
        do {
            for item in targets {
                let contents = try FileManager.default.contentsOfDirectory(at: item.url, includingPropertiesForKeys: nil)
                for file in contents { try FileManager.default.removeItem(at: file) }
            }
            status = "Removed \(targets.map(\.size).reduce(0, +).tidySize)."
            scan()
        } catch { status = "Couldn’t finish cleanup: \(error.localizedDescription)" }
    }

    nonisolated private static func directorySize(_ url: URL, manager: FileManager) -> Int64 {
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = manager.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in enumerator {
            let values = try? file.resourceValues(forKeys: keys)
            if values?.isRegularFile == true { total += Int64(values?.fileSize ?? 0) }
        }
        return total
    }
}
