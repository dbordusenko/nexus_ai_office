import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingFlow: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @Namespace private var animation

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "PDF without\nfriction.",
            subtitle: "The fastest AI PDF toolkit\nfor iPhone and iPad.",
            gradient: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
            illustration: .flyingPapers
        ),
        OnboardingPage(
            id: 1,
            title: "AI that reads\nyour PDFs.",
            subtitle: "Ask questions, get summaries,\ntranslate and analyze contracts.",
            gradient: [Color(hex: "#5E5CE6"), Color(hex: "#AF52DE")],
            illustration: .aiOrb
        ),
        OnboardingPage(
            id: 2,
            title: "Convert\nanything.",
            subtitle: "PDF to Word, Excel, PPTX.\nIn seconds. No watermarks.",
            gradient: [Color(hex: "#FF9F0A"), Color(hex: "#FF6B35")],
            illustration: .conversion
        ),
        OnboardingPage(
            id: 3,
            title: "Your vault.\nYour rules.",
            subtitle: "Face ID protection, iCloud sync,\nend-to-end encrypted.",
            gradient: [Color(hex: "#34C759"), Color(hex: "#30B0C7")],
            illustration: .vault
        ),
    ]

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(colors: pages[currentPage].gradient)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") {
                        complete()
                    }
                    .font(FlyFont.body())
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.2), in: Capsule())
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }

                Spacer()

                // Illustration
                OnboardingIllustration(page: pages[currentPage])
                    .frame(height: 300)
                    .id("illustration_\(currentPage)")
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                    .animation(FlySpring.hero, value: currentPage)

                Spacer()

                // Text
                VStack(alignment: .leading, spacing: 14) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 42, weight: .black))
                        .foregroundStyle(.white)
                        .lineSpacing(2)
                        .id("title_\(currentPage)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(FlySpring.standard.delay(0.05), value: currentPage)

                    Text(pages[currentPage].subtitle)
                        .font(FlyFont.body(18))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                        .id("sub_\(currentPage)")
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(FlySpring.standard.delay(0.10), value: currentPage)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FlySpacing.xl)

                // Nav row
                HStack {
                    // Page dots
                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(.white)
                                .frame(width: i == currentPage ? 28 : 7, height: 7)
                                .opacity(i == currentPage ? 1 : 0.45)
                                .animation(FlySpring.snappy, value: currentPage)
                        }
                    }

                    Spacer()

                    // CTA button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(FlySpring.standard) {
                                currentPage += 1
                                FlyHaptic.light()
                            }
                        } else {
                            complete()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .font(FlyFont.body(17))
                                .fontWeight(.semibold)

                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(pages[currentPage].gradient.first ?? FlyColor.electricBlue)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
                    }
                    .buttonStyle(.flyPress)
                }
                .padding(.horizontal, FlySpacing.xl)
                .padding(.top, FlySpacing.xl)
                .padding(.bottom, FlySpacing.xxl)
            }
        }
    }

    private func complete() {
        FlyHaptic.success()
        withAnimation(FlySpring.hero) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let gradient: [Color]
    let illustration: IllustrationType

    enum IllustrationType {
        case flyingPapers
        case aiOrb
        case conversion
        case vault
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            // Subtle floating circles for depth
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 300)
                .offset(x: -80, y: -200 + phase * 20)
                .blur(radius: 40)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 200)
                .offset(x: 120, y: 100 - phase * 15)
                .blur(radius: 30)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
        .animation(.easeInOut(duration: 0.7), value: colors.first)
    }
}

// MARK: - Onboarding Illustration

struct OnboardingIllustration: View {
    let page: OnboardingPage
    @State private var animate = false

    var body: some View {
        ZStack {
            // Outer ambient ring
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 280)
                .scaleEffect(animate ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 340)
                .scaleEffect(animate ? 1.0 : 1.05)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animate)

            switch page.illustration {
            case .flyingPapers:  FlyingPapersIllustration(animate: animate)
            case .aiOrb:         AIBrainIllustration(animate: animate)
            case .conversion:    ConversionIllustration(animate: animate)
            case .vault:         VaultIllustration(animate: animate)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Flying Papers

struct FlyingPapersIllustration: View {
    let animate: Bool

    private let papers: [(offset: CGSize, rotation: Double, opacity: Double, delay: Double)] = [
        (CGSize(width: -55, height: 15),  -22, 1.00, 0.0),
        (CGSize(width: -28, height: -18),  -8, 0.90, 0.1),
        (CGSize(width:   0, height: -40),   0, 1.00, 0.0),
        (CGSize(width:  28, height: -18),   8, 0.90, 0.1),
        (CGSize(width:  55, height:  15),  22, 0.80, 0.2),
    ]

    var body: some View {
        ZStack {
            ForEach(papers.indices, id: \.self) { i in
                let paper = papers[i]
                PaperCard()
                    .rotationEffect(.degrees(paper.rotation))
                    .offset(
                        x: paper.offset.width + (animate ? CGFloat(i - 2) * 6 : 0),
                        y: paper.offset.height + (animate ? CGFloat(i) * -5 : 0)
                    )
                    .opacity(paper.opacity)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .animation(
                        .spring(response: 1.4, dampingFraction: 0.55)
                            .repeatForever(autoreverses: true)
                            .delay(paper.delay),
                        value: animate
                    )
            }
        }
    }
}

struct PaperCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.white.opacity(0.95))
            .frame(width: 88, height: 114)
            .overlay(alignment: .top) {
                VStack(spacing: 5) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(i == 0 ? 0.35 : 0.18))
                            .frame(height: 5)
                            .padding(.horizontal, i == 0 ? 12 : 16)
                    }
                }
                .padding(.top, 14)
            }
    }
}

// MARK: - AI Brain

struct AIBrainIllustration: View {
    let animate: Bool
    @State private var sparkleAngles: [Double] = [0, 60, 120, 180, 240, 300]

    var body: some View {
        ZStack {
            // Orbiting sparkles
            ForEach(sparkleAngles.indices, id: \.self) { i in
                let angle = sparkleAngles[i]
                let radians = angle * .pi / 180
                let radius: CGFloat = 100

                Image(systemName: "sparkle")
                    .font(.system(size: i % 2 == 0 ? 14 : 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
                    .scaleEffect(animate ? 1.1 : 0.8)
                    .opacity(animate ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(i) * 0.25),
                        value: animate
                    )
            }

            // Central orb
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: 120)
                .blur(radius: 20)

            Circle()
                .fill(.white)
                .frame(width: 90)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#5E5CE6"), Color(hex: "#AF52DE")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animate ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                }
                .shadow(color: .white.opacity(0.5), radius: 20)
        }
    }
}

// MARK: - Conversion

struct ConversionIllustration: View {
    let animate: Bool

    private let formats: [(label: String, icon: String, color: Color)] = [
        ("PDF",  "doc.fill",         Color(hex: "#FF3B30")),
        ("DOC",  "doc.text.fill",    Color(hex: "#2B7CD3")),
        ("XLS",  "tablecells.fill",  Color(hex: "#217346")),
        ("PPT",  "rectangle.on.rectangle.fill", Color(hex: "#D24726")),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(formats.indices, id: \.self) { i in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(formats[i].color)
                        .frame(width: 60, height: 74)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: formats[i].icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(formats[i].label)
                                    .font(FlyFont.label(10))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .shadow(color: formats[i].color.opacity(0.4), radius: 10, y: 5)
                        .offset(y: animate ? (i % 2 == 0 ? -10 : 10) : 0)
                        .animation(
                            .spring(response: 1.2, dampingFraction: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.15),
                            value: animate
                        )

                    if i < formats.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .offset(y: 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Vault

struct VaultIllustration: View {
    let animate: Bool
    @State private var locked = true

    var body: some View {
        ZStack {
            // Vault body
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.2))
                .frame(width: 160, height: 180)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.5), lineWidth: 2)
                }

            VStack(spacing: 16) {
                Image(systemName: animate ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.white)
                    .animation(FlySpring.bouncy, value: animate)

                HStack(spacing: 6) {
                    ForEach(0..<6) { _ in
                        Circle()
                            .fill(.white.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // Face ID lines
            if animate {
                Image(systemName: "faceid")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.4))
                    .offset(y: 60)
                    .transition(.opacity)
            }
        }
        .scaleEffect(animate ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
    }
}
