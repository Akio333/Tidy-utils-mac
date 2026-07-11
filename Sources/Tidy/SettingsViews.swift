import SwiftUI

struct CleaningView: View {
    @EnvironmentObject private var state: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Make space, intentionally", subtitle: "Review caches, logs and Trash before anything is removed.")
            HStack { Text(state.cleaner.status).foregroundStyle(.secondary); Spacer(); Button("Scan") { state.cleaner.scan() }.buttonStyle(.borderedProminent).disabled(state.cleaner.isScanning) }
            List(state.cleaner.items) { item in
                Button { state.cleaner.toggle(item) } label: { HStack(spacing: 14) {
                    Image(systemName: item.selected ? "checkmark.circle.fill" : "circle").foregroundStyle(item.selected ? .indigo : .secondary)
                    VStack(alignment: .leading) { Text(item.name); Text(item.location).font(.caption).foregroundStyle(.secondary) }
                    Spacer(); Text(item.size.tidySize).monospacedDigit().foregroundStyle(.secondary)
                } }.buttonStyle(.plain)
            }.overlay { if state.cleaner.items.isEmpty && !state.cleaner.isScanning { ContentUnavailableView("No scan yet", systemImage: "sparkle.magnifyingglass", description: Text("Select Scan to find common reclaimable files.")) } }
            HStack { Text("Selected items are emptied permanently.").font(.caption).foregroundStyle(.secondary); Spacer(); Button("Clean selected") { state.cleaner.cleanSelected() }.buttonStyle(.borderedProminent).disabled(state.cleaner.items.allSatisfy { !$0.selected }) }
        }.padding(28)
    }
}

struct DisplayView: View {
    @EnvironmentObject private var state: AppState
    @State private var selectedMode = ""
    private var service: DisplayService { state.display }
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
    @EnvironmentObject private var state: AppState
    private var service: MouseService { state.mouse }
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
