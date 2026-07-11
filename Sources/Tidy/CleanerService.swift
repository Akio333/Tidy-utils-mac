import Foundation

@MainActor
final class CleanerService: ObservableObject {
    @Published private(set) var items: [CleanableItem] = []
    @Published private(set) var isScanning = false
    @Published var status = "Scan for reclaimable files when you’re ready."

    var selectedCount: Int { items.filter(\.selected).count }
    var selectedSize: Int64 { items.filter(\.selected).map(\.size).reduce(0, +) }
    var allSelected: Bool { !items.isEmpty && items.allSatisfy(\.selected) }

    func scan() {
        isScanning = true
        status = "Scanning common cache locations…"
        let roots: [(String, URL)] = [
            ("Application Caches", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Caches")),
            ("Application Logs", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Logs")),
            ("Trash", FileManager.default.homeDirectoryForCurrentUser.appending(path: ".Trash")),
            ("Homebrew Cache", FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Caches/Homebrew"))
        ]
        Task.detached { [roots] in
            let manager = FileManager.default
            var result = roots.flatMap { category, root in
                Self.items(in: root, category: category, manager: manager)
            }
            // Homebrew has its own category, so do not show it twice under application caches.
            result.removeAll { $0.category == "Application Caches" && $0.name == "Homebrew" }
            result.sort {
                $0.category == $1.category
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : $0.category < $1.category
            }
            await MainActor.run {
                self.items = result
                self.isScanning = false
                self.status = result.isEmpty ? "Nothing obvious to clean." : "Found \(result.count) folders and files totaling \(result.map(\.size).reduce(0, +).tidySize)."
            }
        }
    }

    func toggle(_ item: CleanableItem) {
        guard let index = items.firstIndex(of: item) else { return }
        items[index].selected.toggle()
    }

    func setAllSelected(_ selected: Bool) {
        for index in items.indices { items[index].selected = selected }
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

    nonisolated private static func items(in root: URL, category: String, manager: FileManager) -> [CleanableItem] {
        guard let urls = try? manager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles]) else { return [] }
        return urls.map { url in
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            let size = values?.isRegularFile == true ? Int64(values?.fileSize ?? 0) : directorySize(url, manager: manager)
            return CleanableItem(id: url, name: url.lastPathComponent, location: url.path, category: category, url: url, size: size)
        }
    }

}
