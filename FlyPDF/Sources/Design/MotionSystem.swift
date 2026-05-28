import SwiftUI

// MARK: - Motion Design System

// All FlyPDF animations follow these principles:
// 1. Spring-based (never linear for UI)
// 2. Staggered entry (40-80ms between items)
// 3. Never block interaction
// 4. Haptic sync with visual moments
// 5. 120fps ProMotion ready (no frame-rate-sensitive logic)

// MARK: - Transition Library

extension AnyTransition {

    // Card enters from right, exits to left (list navigation pattern)
    static var flyCardEntry: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    // Sheet-like: slides up from bottom
    static var flySheetEntry: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal:   .move(edge: .bottom).combined(with: .opacity)
        )
    }

    // Chip/badge pops in
    static var flyPopIn: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.7).combined(with: .opacity),
            removal:   .scale(scale: 0.9).combined(with: .opacity)
        )
    }

    // Processing items appear with scale+fade
    static var flyItemAppear: AnyTransition {
        .scale(scale: 0.85).combined(with: .opacity)
    }
}

// MARK: - Entrance Animator

struct StaggeredAppear: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(FlySpring.standard.delay(delay), value: appeared)
            .onAppear { appeared = true }
    }
}

extension View {
    func flyAppear(delay: Double = 0) -> some View {
        modifier(StaggeredAppear(delay: delay))
    }
}

// MARK: - Scroll Reveal

struct ScrollRevealModifier: ViewModifier {
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 20)
            .onAppear {
                withAnimation(FlySpring.standard) {
                    visible = true
                }
            }
    }
}

extension View {
    func flyScrollReveal() -> some View {
        modifier(ScrollRevealModifier())
    }
}

// MARK: - Pulse Effect

struct PulseModifier: ViewModifier {
    @State private var pulsing = false
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulsing ? 0.6 : 0.2), radius: pulsing ? radius : radius * 0.5)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)
            .onAppear { pulsing = true }
    }
}

extension View {
    func flyPulse(color: Color = FlyColor.electricBlue, radius: CGFloat = 16) -> some View {
        modifier(PulseModifier(color: color, radius: radius))
    }
}

// MARK: - Shimmer Effect (Loading)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 1.5)
                    .blendMode(.screen)
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
                }
                .clipShape(RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous))
            }
            .onAppear { phase = 1 }
    }
}

extension View {
    func flyShimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Hero Transition (Document → Viewer)

struct HeroTransitionModifier: ViewModifier {
    let namespace: Namespace.ID
    let id: String

    func body(content: Content) -> some View {
        content.matchedGeometryEffect(id: id, in: namespace)
    }
}

extension View {
    func flyHeroSource(namespace: Namespace.ID, id: String) -> some View {
        matchedGeometryEffect(id: id, in: namespace, isSource: true)
    }

    func flyHeroDestination(namespace: Namespace.ID, id: String) -> some View {
        matchedGeometryEffect(id: id, in: namespace, isSource: false)
    }
}

// MARK: - Floating Paper Particle System

struct FlyingPaperParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
}

class ParticleSystem: ObservableObject {
    @Published var particles: [FlyingPaperParticle] = []
    private var timer: Timer?

    func burst(from origin: CGPoint, count: Int = 12, colors: [Color] = [FlyColor.electricBlue, FlyColor.violet, FlyColor.success]) {
        let new = (0..<count).map { _ in
            FlyingPaperParticle(
                position: origin,
                velocity: CGVector(
                    dx: Double.random(in: -100...100),
                    dy: Double.random(in: -200 ... -50)
                ),
                rotation: Double.random(in: -45...45),
                scale: CGFloat.random(in: 0.5...1.2),
                opacity: 1.0,
                color: colors.randomElement()!
            )
        }
        particles.append(contentsOf: new)

        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.particles = self.particles.compactMap { p in
                var updated = p
                updated.position.x += p.velocity.dx * 0.016
                updated.position.y += p.velocity.dy * 0.016
                updated.velocity.dy += 9.8 * 0.016 * 20
                updated.opacity -= 0.018
                updated.rotation += p.velocity.dx * 0.01
                return updated.opacity > 0 ? updated : nil
            }
            if self.particles.isEmpty { t.invalidate() }
        }
    }
}

// MARK: - Loading Skeleton

struct DocumentSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(FlyColor.secondaryBg)
                .frame(width: 50, height: 62)
                .flyShimmer()

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(FlyColor.secondaryBg)
                    .frame(height: 14)
                    .flyShimmer()

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(FlyColor.secondaryBg)
                    .frame(width: 120, height: 10)
                    .flyShimmer()

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(FlyColor.secondaryBg)
                    .frame(width: 80, height: 10)
                    .flyShimmer()
            }

            Spacer()
        }
        .padding(FlySpacing.md)
        .background(FlyColor.background, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
    }
}

// MARK: - Loading State View

struct LoadingState: View {
    var body: some View {
        LazyVStack(spacing: 10) {
            ForEach(0..<5, id: \.self) { _ in
                DocumentSkeleton()
            }
        }
        .padding(.horizontal, FlySpacing.lg)
    }
}

// MARK: - Success Burst

struct SuccessBurst: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 1.0
    let onDone: () -> Void

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                let angle = Double(i) * 45 * .pi / 180
                Circle()
                    .fill([FlyColor.electricBlue, FlyColor.violet, FlyColor.success][i % 3])
                    .frame(width: 10, height: 10)
                    .offset(
                        x: cos(angle) * 60 * scale,
                        y: sin(angle) * 60 * scale
                    )
                    .opacity(opacity)
            }

            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(FlyColor.success)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(FlySpring.bouncy) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.8)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onDone()
            }
        }
    }
}
