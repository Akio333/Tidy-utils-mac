import SwiftUI

struct CleaningView: View {
    @ObservedObject var service: CleanerService
    @State private var confirmsDeletion = false

    private var categories: [String] {
        Array(Set(service.items.map(\.category))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Make space, intentionally", subtitle: "Review caches, logs and Trash before anything is removed.")
            HStack {
                Text(service.status).foregroundStyle(.secondary)
                Spacer()
                if service.isScanning { ProgressView().controlSize(.small) }
                Button("Scan again") { service.scan() }.disabled(service.isScanning)
                Button(service.allSelected ? "Select none" : "Select all") { service.setAllSelected(!service.allSelected) }
                    .disabled(service.items.isEmpty)
            }
            List {
                ForEach(categories, id: \.self) { category in
                    Section(category) {
                        ForEach(service.items.filter { $0.category == category }) { item in
                            Button { service.toggle(item) } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: item.selected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.selected ? .indigo : .secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name)
                                        Text(item.location).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    Text(item.size.tidySize).monospacedDigit().foregroundStyle(.secondary)
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlay {
                if service.items.isEmpty && !service.isScanning {
                    ContentUnavailableView("No reclaimable folders found", systemImage: "sparkle.magnifyingglass")
                }
            }
            HStack {
                Text("\(service.selectedCount) selected · \(service.selectedSize.tidySize). Selected items are removed permanently.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Clean selected", role: .destructive) { confirmsDeletion = true }
                    .buttonStyle(.borderedProminent)
                    .disabled(service.selectedCount == 0 || service.isScanning)
            }
        }
        .padding(28)
        .task { if service.items.isEmpty && !service.isScanning { service.scan() } }
        .confirmationDialog("Delete \(service.selectedCount) selected items?", isPresented: $confirmsDeletion) {
            Button("Delete permanently", role: .destructive) { service.cleanSelected() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove \(service.selectedSize.tidySize). This action cannot be undone.")
        }
    }
}

struct DisplayView: View {
    @ObservedObject var service: DisplayService
    @State private var selectedMode = ""
    var body: some View {
        Form {
            Section { SectionHeader(title: "Displays, precisely tuned", subtitle: "Use macOS display modes and DDC controls where your monitor supports them.") }
            Section("Connected displays") {
                Picker("Display", selection: binding(\DisplayService.selectedDisplayID)) { ForEach(service.displays) { display in Text("\(display.name) · \(display.width) × \(display.height)").tag(Optional(display.id)) } }
                Button("Refresh displays") { service.refresh() }
            }
            Section("Resolution") {
                Picker("Mode", selection: $selectedMode) { Text("Choose a mode").tag(""); ForEach(service.availableModes(), id: \.self) { mode in Text("\(mode.width) × \(mode.height) · \(Int(mode.refreshRate)) Hz").tag("\(mode.width)x\(mode.height)-\(mode.refreshRate)") } }
                Button("Apply resolution") { if let mode = service.availableModes().first(where: { "\($0.width)x\($0.height)-\($0.refreshRate)" == selectedMode }) { service.applyDisplayMode(mode) } }.disabled(selectedMode.isEmpty)
            }
            Section("External monitor controls") {
                Slider(value: binding(\DisplayService.brightness), in: 0...100, step: 1) { Text("Brightness") } minimumValueLabel: { Image(systemName: "sun.min") } maximumValueLabel: { Image(systemName: "sun.max") }.onChange(of: service.brightness) { service.setBrightness() }
                Slider(value: binding(\DisplayService.volume), in: 0...100, step: 1) { Text("Volume") } minimumValueLabel: { Image(systemName: "speaker") } maximumValueLabel: { Image(systemName: "speaker.wave.3") }.onChange(of: service.volume) { service.setVolume() }
                Toggle("Turn off built-in display with external monitor", isOn: binding(\DisplayService.turnOffInternalDisplay)).disabled(true)
                Text("macOS restricts programmatic disabling of the built-in display. This preference is saved for a future privileged display helper.").font(.caption).foregroundStyle(.secondary)
            }
            if !service.status.isEmpty { Text(service.status).font(.callout).foregroundStyle(.secondary) }
        }.formStyle(.grouped).padding(18)
    }
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<DisplayService, T>) -> Binding<T> { Binding(get: { service[keyPath: keyPath] }, set: { service[keyPath: keyPath] = $0 }) }
}

struct MouseView: View {
    @ObservedObject var service: MouseService
    var body: some View {
        Form {
            Section { SectionHeader(title: "Pointer, your way", subtitle: "Keep trackpad and mouse behaviour distinct, with settings retained across launches.") }
            Section("Scrolling") {
                Toggle("Natural scrolling on trackpad", isOn: binding(\MouseService.trackpadNaturalScrolling))
                Toggle("Natural scrolling on mouse", isOn: binding(\MouseService.mouseNaturalScrolling))
                Text("Per-device scrolling needs an accessibility event-tap helper to take effect. The preference is already retained here.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Pointer") {
                Toggle("Disable mouse acceleration", isOn: binding(\MouseService.disableAcceleration))
                Button("Apply acceleration setting") { service.applyAcceleration() }
            }
            Section("Extra buttons") {
                Picker("Button mapping", selection: binding(\MouseService.extraButtonAction)) { Text("Back / Forward").tag("Back / Forward"); Text("Mission Control").tag("Mission Control"); Text("No action").tag("No action") }
                Text("Extra button mappings require Accessibility permission and an event-tap helper; this view stores the intended mapping.").font(.caption).foregroundStyle(.secondary)
            }
            Text(service.status).foregroundStyle(.secondary)
        }.formStyle(.grouped).padding(18)
    }
    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<MouseService, T>) -> Binding<T> { Binding(get: { service[keyPath: keyPath] }, set: { service[keyPath: keyPath] = $0 }) }
}
