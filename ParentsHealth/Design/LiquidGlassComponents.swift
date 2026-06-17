import SwiftUI

/// Applies Liquid Glass on iOS 26+ with material fallback on earlier versions.
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardRadius
    var interactive: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    interactive ? .regular.interactive() : .regular,
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                )
        }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = AppTheme.cardRadius, interactive: Bool = false) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}

struct HealthGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.midnight,
                    AppTheme.deepTeal.opacity(0.85),
                    Color(red: 0.08, green: 0.22, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.warmCoral.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -120, y: -180)

            Circle()
                .fill(AppTheme.softMint.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: 320)

            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 80, y: -40)
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = AppTheme.cardRadius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlass(cornerRadius: cornerRadius)
    }
}

struct MetricChip: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.captionMuted)
                .foregroundStyle(.white.opacity(0.75))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.metricValue)
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                .fill(color.opacity(isSelected ? 0.45 : 0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(isSelected ? 0.5 : 0.2), lineWidth: 1)
        )
    }
}

struct GlassFAB: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .liquidGlass(cornerRadius: 29, interactive: true)
                .shadow(color: AppTheme.warmCoral.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct ParentAvatar: View {
    let initials: String
    let hue: Double
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.55, brightness: 0.75),
                            Color(hue: hue + 0.08, saturation: 0.45, brightness: 0.85),
                            Color(hue: hue, saturation: 0.55, brightness: 0.75)
                        ],
                        center: .center
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct HealthScoreRing: View {
    let score: Int
    var size: CGFloat = 120

    private var progress: Double { Double(score) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.softMint, AppTheme.warmCoral],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Health")
                    .font(.captionMuted)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: size, height: size)
    }
}
