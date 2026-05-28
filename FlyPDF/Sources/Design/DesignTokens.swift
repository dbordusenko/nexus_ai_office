import SwiftUI

// MARK: - Color Palette

enum FlyColor {

    // MARK: Brand
    static let electricBlue    = Color(hex: "#007AFF")
    static let violet          = Color(hex: "#5E5CE6")
    static let deepViolet      = Color(hex: "#3A37B4")
    static let ultraViolet     = Color(hex: "#AF52DE")

    // MARK: Neutrals
    static let graphite        = Color(hex: "#1C1C1E")
    static let softGraphite    = Color(hex: "#2C2C2E")
    static let silver          = Color(hex: "#8E8E93")
    static let mist            = Color(hex: "#F2F2F7")
    static let snow            = Color(hex: "#F9F9FB")

    // MARK: Semantic
    static let success         = Color(hex: "#34C759")
    static let warning         = Color(hex: "#FF9F0A")
    static let error           = Color(hex: "#FF3B30")
    static let info            = Color(hex: "#32ADE6")

    // MARK: Dynamic (light/dark adaptive)
    static let background      = Color(.systemBackground)
    static let secondaryBg     = Color(.secondarySystemBackground)
    static let tertiaryBg      = Color(.tertiarySystemBackground)
    static let label           = Color(.label)
    static let secondaryLabel  = Color(.secondaryLabel)
    static let tertiaryLabel   = Color(.tertiaryLabel)
    static let separator       = Color(.separator)

    // MARK: Glass
    static let glassLight      = Color.white.opacity(0.72)
    static let glassDark       = Color(hex: "#1C1C1E").opacity(0.72)

    // MARK: Gradients
    static let brandGradient = LinearGradient(
        colors: [electricBlue, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [electricBlue, violet, ultraViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: "#FF9F0A"), Color(hex: "#FF6B35")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let successGradient = LinearGradient(
        colors: [Color(hex: "#34C759"), Color(hex: "#30B0C7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography

enum FlyFont {
    static func display(_ size: CGFloat = 34, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func heading(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func subheading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

// MARK: - Spacing (8pt grid)

enum FlySpacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let xxl:  CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum FlyRadius {
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 18
    static let lg:   CGFloat = 24
    static let xl:   CGFloat = 32
    static let pill: CGFloat = 100
}

// MARK: - Shadow Modifiers

extension View {
    func flyShadowSoft() -> some View {
        self
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.04), radius: 24, x: 0, y: 8)
    }

    func flyShadowBlue() -> some View {
        self.shadow(color: FlyColor.electricBlue.opacity(0.32), radius: 16, x: 0, y: 6)
    }

    func flyShadowViolet() -> some View {
        self.shadow(color: FlyColor.violet.opacity(0.32), radius: 16, x: 0, y: 6)
    }

    func flyShadowCard() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Glassmorphism

struct GlassBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = FlyRadius.lg
    var tint: Color = .clear

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.05))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.12)
                                    : Color.white.opacity(0.72),
                                lineWidth: 1
                            )
                    }
            }
    }
}

extension View {
    func flyGlass(
        cornerRadius: CGFloat = FlyRadius.lg,
        tint: Color = .clear
    ) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Spring Animations

enum FlySpring {
    static let snappy    = Animation.spring(response: 0.25, dampingFraction: 0.75)
    static let standard  = Animation.spring(response: 0.35, dampingFraction: 0.70)
    static let bouncy    = Animation.spring(response: 0.45, dampingFraction: 0.60)
    static let slow      = Animation.spring(response: 0.60, dampingFraction: 0.75)
    static let hero      = Animation.spring(response: 0.50, dampingFraction: 0.80)
}

// MARK: - Haptic Feedback

enum FlyHaptic {
    static func light()    { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()   { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy()    { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success()  { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error()    { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func warning()  { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}

// MARK: - Press Button Style

struct FlyPressButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(FlySpring.snappy, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed { FlyHaptic.light() }
            }
    }
}

extension ButtonStyle where Self == FlyPressButtonStyle {
    static var flyPress: FlyPressButtonStyle { FlyPressButtonStyle() }
    static func flyPress(scale: CGFloat) -> FlyPressButtonStyle {
        FlyPressButtonStyle(scale: scale)
    }
}
