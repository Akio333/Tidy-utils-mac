import SwiftUI

struct CleaningView: View {
    @ObservedObject var service: CleanerService
    @State private var confirmsDeletion = false

    private var categories: [String] {
        Array(Set(service.items.map(\.category))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                PageHeader(
                    title: "Cleaning",
                    subtitle: "Review and remove caches, logs, and other disposable files.",
                    symbol: "sparkles",
                    tint: TidyTheme.green
                )
                Spacer()
                Button {
                    service.scan()
                } label: {
                    Label("Scan again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(service.isScanning)
            }

            HStack(spacing: 12) {
                StatusCapsule(
                    text: service.isScanning ? "Scanning" : service.status,
                    symbol: service.isScanning ? "magnifyingglass" : "checkmark.circle.fill",
                    tint: service.isScanning ? TidyTheme.accent : TidyTheme.green
                )
                .lineLimit(1)

                if service.isScanning {
                    ProgressView().controlSize(.small)
                }

                Spacer()

                Button(service.allSelected ? "Select none" : "Select all") {
                    service.setAllSelected(!service.allSelected)
                }
                .buttonStyle(.bordered)
                .disabled(service.items.isEmpty)
            }

            VStack(spacing: 0) {
                List {
                    ForEach(categories, id: \.self) { category in
                        Section {
                            ForEach(service.items.filter { $0.category == category }) { item in
                                CleanupRow(item: item) { service.toggle(item) }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 2)
                            }
                        } header: {
                            HStack {
                                Image(systemName: categoryIcon(category))
                                    .foregroundStyle(TidyTheme.green)
                                Text(category)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                let count = service.items.filter { $0.category == category }.count
                                Text("\(count) item\(count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .textCase(nil)
                            .padding(.bottom, 5)
                        }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .overlay {
                    if service.items.isEmpty && !service.isScanning {
                        ContentUnavailableView(
                            "Your Mac looks tidy",
                            systemImage: "sparkles",
                            description: Text("Run a scan to look for disposable files.")
                        )
                    }
                }
            }
            .tidyGlass(cornerRadius: 22, tint: TidyTheme.green)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(service.selectedCount) selected")
                        .font(.headline)
                    Text("\(service.selectedSize.tidySize) will be permanently removed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Clean selected", role: .destructive) {
                    confirmsDeletion = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(TidyTheme.red)
                .disabled(service.selectedCount == 0 || service.isScanning)
            }
            .padding(18)
            .tidyGlass(cornerRadius: 18, tint: TidyTheme.red, interactive: true)
        }
        .padding(28)
        .frame(maxWidth: 1180, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            if service.items.isEmpty && !service.isScanning { service.scan() }
        }
        .confirmationDialog("Delete \(service.selectedCount) selected items?", isPresented: $confirmsDeletion) {
            Button("Delete permanently", role: .destructive) { service.cleanSelected() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove \(service.selectedSize.tidySize). This action cannot be undone.")
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Trash": "trash"
        case "Application Logs": "doc.text.magnifyingglass"
        case "Homebrew Cache": "shippingbox"
        default: "archivebox"
        }
    }
}

private struct CleanupRow: View {
    let item: CleanableItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: item.selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.selected ? TidyTheme.green : .secondary)
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.callout.weight(.medium))
                    Text(item.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Text(item.size.tidySize)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.055), in: Capsule())
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background(
                item.selected ? TidyTheme.green.opacity(0.055) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DisplayView: View {
    @ObservedObject var service: DisplayService
    @State private var selectedMode = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    PageHeader(
                        title: "Displays",
                        subtitle: "Configure resolution and external monitor controls.",
                        symbol: "display.2",
                        tint: TidyTheme.purple
                    )
                    Spacer()
                    Button {
                        service.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                GlassSection(
                    title: "Connected displays",
                    subtitle: "Choose the display you want to configure.",
                    symbol: "display",
                    tint: TidyTheme.purple
                ) {
                    SettingRow(
                        title: "Active display",
                        detail: selectedDisplayDescription,
                        symbol: "rectangle.on.rectangle",
                        tint: TidyTheme.purple
                    ) {
                        Picker("Display", selection: binding(\DisplayService.selectedDisplayID)) {
                            ForEach(service.displays) { display in
                                Text(display.name).tag(Optional(display.id))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 210)
                    }
                }

                GlassSection(
                    title: "Resolution",
                    subtitle: "Changes are applied as soon as you select a mode.",
                    symbol: "rectangle.arrowtriangle.2.outward",
                    tint: TidyTheme.cyan
                ) {
                    SettingRow(
                        title: "Display mode",
                        detail: "Resolution and refresh rate",
                        symbol: "aspectratio",
                        tint: TidyTheme.cyan
                    ) {
                        Picker("Mode", selection: $selectedMode) {
                            Text("Choose a mode").tag("")
                            ForEach(service.availableModes(), id: \.self) { mode in
                                Text("\(mode.width) × \(mode.height) · \(Int(mode.refreshRate)) Hz")
                                    .tag("\(mode.width)x\(mode.height)-\(mode.refreshRate)")
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 240)
                        .onChange(of: selectedMode) { _, modeIdentifier in
                            guard let mode = service.availableModes().first(where: {
                                "\($0.width)x\($0.height)-\($0.refreshRate)" == modeIdentifier
                            }) else { return }
                            service.applyDisplayMode(mode)
                        }
                    }
                }

                GlassSection(
                    title: "External monitor",
                    subtitle: "DDC controls are applied automatically.",
                    symbol: "slider.horizontal.3",
                    tint: TidyTheme.orange
                ) {
                    VStack(spacing: 18) {
                        MonitorSlider(
                            title: "Brightness",
                            value: binding(\DisplayService.brightness),
                            leadingSymbol: "sun.min",
                            trailingSymbol: "sun.max.fill",
                            tint: TidyTheme.orange
                        )
                        .onChange(of: service.brightness) { service.setBrightness() }

                        Divider()

                        MonitorSlider(
                            title: "Volume",
                            value: binding(\DisplayService.volume),
                            leadingSymbol: "speaker",
                            trailingSymbol: "speaker.wave.3.fill",
                            tint: TidyTheme.purple
                        )
                        .onChange(of: service.volume) { service.setVolume() }

                        Divider()

                        SettingRow(
                            title: "Turn off built-in display",
                            detail: "Available after installing the privileged display helper.",
                            symbol: "laptopcomputer.slash",
                            tint: TidyTheme.red
                        ) {
                            Toggle("", isOn: binding(\DisplayService.turnOffInternalDisplay))
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .disabled(true)
                        }
                    }
                }

                if !service.status.isEmpty {
                    StatusCapsule(
                        text: service.status,
                        symbol: service.status.localizedCaseInsensitiveContains("error") ? "exclamationmark.triangle.fill" : "info.circle.fill",
                        tint: TidyTheme.accent
                    )
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var selectedDisplayDescription: String {
        guard let display = service.displays.first(where: { $0.id == service.selectedDisplayID }) else {
            return "No display selected"
        }
        return "\(display.width) × \(display.height)\(display.isBuiltIn ? " · Built-in" : " · External")"
    }

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<DisplayService, T>) -> Binding<T> {
        Binding(get: { service[keyPath: keyPath] }, set: { service[keyPath: keyPath] = $0 })
    }
}

private struct MonitorSlider: View {
    let title: String
    @Binding var value: Double
    let leadingSymbol: String
    let trailingSymbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.callout.weight(.medium))
                Spacer()
                Text("\(Int(value))%")
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            }
            HStack(spacing: 10) {
                Image(systemName: leadingSymbol).foregroundStyle(.secondary)
                Slider(value: $value, in: 0...100, step: 1).tint(tint)
                Image(systemName: trailingSymbol).foregroundStyle(tint)
            }
        }
    }
}

struct MouseView: View {
    @ObservedObject var service: MouseService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PageHeader(
                    title: "Mouse",
                    subtitle: "Tune scrolling, pointer movement, and extra buttons.",
                    symbol: "computermouse",
                    tint: TidyTheme.orange
                )

                GlassSection(
                    title: "Scrolling",
                    subtitle: "Keep mouse and trackpad directions independent.",
                    symbol: "arrow.up.and.down",
                    tint: TidyTheme.cyan
                ) {
                    VStack(spacing: 0) {
                        SettingRow(
                            title: "Natural scrolling on trackpad",
                            detail: "Content follows your finger movement.",
                            symbol: "rectangle.and.hand.point.up.left",
                            tint: TidyTheme.cyan
                        ) {
                            Toggle("", isOn: binding(\MouseService.trackpadNaturalScrolling))
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        Divider().padding(.leading, 43).padding(.vertical, 13)

                        SettingRow(
                            title: "Natural scrolling on mouse",
                            detail: "Set the wheel direction separately.",
                            symbol: "computermouse",
                            tint: TidyTheme.orange
                        ) {
                            Toggle("", isOn: binding(\MouseService.mouseNaturalScrolling))
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }
                }

                GlassSection(
                    title: "Pointer",
                    subtitle: "Adjust pointer response.",
                    symbol: "cursorarrow.motionlines",
                    tint: TidyTheme.purple
                ) {
                    SettingRow(
                        title: "Disable mouse acceleration",
                        detail: "Use linear pointer movement for a consistent feel.",
                        symbol: "scope",
                        tint: TidyTheme.purple
                    ) {
                        Toggle("", isOn: accelerationBinding)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }

                GlassSection(
                    title: "Extra buttons",
                    subtitle: "Choose the action for additional mouse buttons.",
                    symbol: "button.programmable",
                    tint: TidyTheme.green
                ) {
                    SettingRow(
                        title: "Button mapping",
                        detail: "Requires Accessibility access to take effect.",
                        symbol: "arrow.left.arrow.right",
                        tint: TidyTheme.green
                    ) {
                        Picker("Button mapping", selection: binding(\MouseService.extraButtonAction)) {
                            Text("Back / Forward").tag("Back / Forward")
                            Text("Mission Control").tag("Mission Control")
                            Text("No action").tag("No action")
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }
                }

                StatusCapsule(text: service.status, symbol: "info.circle.fill", tint: TidyTheme.accent)
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<MouseService, T>) -> Binding<T> {
        Binding(get: { service[keyPath: keyPath] }, set: { service[keyPath: keyPath] = $0 })
    }

    private var accelerationBinding: Binding<Bool> {
        Binding(
            get: { service.disableAcceleration },
            set: { value in
                service.disableAcceleration = value
                service.applyAcceleration()
            }
        )
    }
}
