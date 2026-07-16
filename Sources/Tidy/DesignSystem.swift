import SwiftUI

enum TidyTheme {
    static let accent = Color(red: 0.25, green: 0.43, blue: 0.98)
    static let cyan = Color(red: 0.20, green: 0.75, blue: 0.96)
    static let purple = Color(red: 0.58, green: 0.38, blue: 0.96)
    static let orange = Color(red: 1.00, green: 0.55, blue: 0.22)
    static let red = Color(red: 0.96, green: 0.30, blue: 0.35)
    static let green = Color(red: 0.18, green: 0.72, blue: 0.48)
}

struct TidyWindowBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.08, green: 0.08, blue: 0.13)]
                    : [Color(red: 0.94, green: 0.97, blue: 1.0), Color(red: 0.97, green: 0.96, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(TidyTheme.accent.opacity(colorScheme == .dark ? 0.16 : 0.11))
                .frame(width: 520, height: 520)
                .blur(radius: 110)
                .offset(x: 320, y: -260)

            Circle()
                .fill(TidyTheme.purple.opacity(colorScheme == .dark ? 0.12 : 0.08))
                .frame(width: 440, height: 440)
                .blur(radius: 120)
                .offset(x: -360, y: 330)
        }
        .ignoresSafeArea()
    }
}

private struct GlassSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let tint: Color
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(tint.opacity(0.08)).interactive(interactive),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08),
                    radius: interactive ? 10 : 16,
                    y: interactive ? 4 : 7
                )
        } else {
            fallbackSurface(content: content)
        }
    }

    private func fallbackSurface(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.08 : 0.38),
                                        tint.opacity(colorScheme == .dark ? 0.08 : 0.05),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.20 : 0.72),
                                        Color.white.opacity(0.05),
                                        tint.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.26 : 0.09),
                        radius: interactive ? 12 : 18,
                        y: interactive ? 5 : 8
                    )
            }
    }
}

extension View {
    func tidyGlass(
        cornerRadius: CGFloat = 22,
        tint: Color = TidyTheme.accent,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    let symbol: String
    var tint: Color = TidyTheme.accent

    var body: some View {
        HStack(spacing: 16) {
            SymbolTile(symbol: symbol, tint: tint, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)
        }
    }
}

struct SymbolTile: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                            .stroke(Color.white.opacity(0.38), lineWidth: 0.8)
                    }
                    .shadow(color: tint.opacity(0.28), radius: 10, y: 5)
            }
    }
}

struct GlassSection<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil
    var tint: Color = TidyTheme.accent
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 9) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(tint)
                        .frame(width: 22)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            content
        }
        .padding(20)
        .tidyGlass(tint: tint)
    }
}

struct SettingRow<Control: View>: View {
    let title: String
    var detail: String? = nil
    let symbol: String
    var tint: Color = TidyTheme.accent
    @ViewBuilder let control: Control

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 16)
            control
        }
        .contentShape(Rectangle())
    }
}

struct StatusCapsule: View {
    let text: String
    var symbol: String = "checkmark.circle.fill"
    var tint: Color = TidyTheme.green

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(tint.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.15), lineWidth: 0.7))
    }
}

struct TidyProgressBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.72), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: proxy.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 6)
        .animation(.smooth(duration: 0.45), value: value)
    }
}
