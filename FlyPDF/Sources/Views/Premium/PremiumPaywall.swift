import SwiftUI

// MARK: - Premium Paywall

struct PremiumPaywall: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedPlan: Plan = .annual
    @State private var appeared = false
    @State private var gradientPhase: CGFloat = 0

    enum Plan: String, CaseIterable {
        case monthly  = "Monthly"
        case annual   = "Annual"
        case lifetime = "Lifetime"
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            ZStack {
                Color(hex: "#050A1A")

                LinearGradient(
                    colors: [
                        FlyColor.electricBlue.opacity(0.35),
                        FlyColor.violet.opacity(0.25),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(FlyColor.violet.opacity(0.2))
                    .frame(width: 300)
                    .blur(radius: 80)
                    .offset(x: -80, y: -200 + gradientPhase * 30)

                Circle()
                    .fill(FlyColor.electricBlue.opacity(0.15))
                    .frame(width: 200)
                    .blur(radius: 60)
                    .offset(x: 100, y: 100 - gradientPhase * 20)
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    gradientPhase = 1
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Close
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .buttonStyle(.flyPress)
                        .padding(.trailing, FlySpacing.lg)
                        .padding(.top, FlySpacing.lg)
                    }

                    // MARK: Hero
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.06))
                                .frame(width: 100)

                            Image(systemName: "sparkles")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, FlyColor.electricBlue.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .scaleEffect(appeared ? 1.0 : 0.6)
                                .animation(FlySpring.bouncy.delay(0.1), value: appeared)
                        }

                        Text("Unlock FlyPDF Pro")
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.white)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)
                            .animation(FlySpring.standard.delay(0.15), value: appeared)

                        Text("AI-powered PDF tools. Unlimited.")
                            .font(FlyFont.body(18))
                            .foregroundStyle(.white.opacity(0.75))
                            .opacity(appeared ? 1 : 0)
                            .animation(FlySpring.standard.delay(0.2), value: appeared)
                    }
                    .padding(.top, FlySpacing.md)
                    .padding(.bottom, FlySpacing.xl)

                    // MARK: Features
                    VStack(spacing: 10) {
                        ForEach(Array(features.enumerated()), id: \.element.text) { i, feature in
                            FeatureRow(feature: feature)
                                .opacity(appeared ? 1 : 0)
                                .offset(x: appeared ? 0 : -20)
                                .animation(FlySpring.standard.delay(0.25 + Double(i) * 0.05), value: appeared)
                        }
                    }
                    .padding(.horizontal, FlySpacing.lg)
                    .padding(.bottom, FlySpacing.xl)

                    // MARK: Plan Picker
                    PlanPicker(selected: $selectedPlan)
                        .padding(.horizontal, FlySpacing.lg)
                        .padding(.bottom, FlySpacing.xl)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(FlySpring.standard.delay(0.5), value: appeared)

                    // MARK: CTA
                    VStack(spacing: 14) {
                        Button {
                            FlyHaptic.success()
                            appState.isPremium = true
                            dismiss()
                        } label: {
                            Text(ctaLabel)
                                .font(FlyFont.body(18))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(FlyColor.brandGradient, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
                                .flyShadowBlue()
                        }
                        .buttonStyle(.flyPress)

                        Text("Cancel anytime. No commitments.")
                            .font(FlyFont.caption(12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, FlySpacing.lg)
                    .opacity(appeared ? 1 : 0)
                    .animation(FlySpring.standard.delay(0.55), value: appeared)

                    // Legal
                    HStack(spacing: FlySpacing.md) {
                        Button("Restore Purchases") {}
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Button("Privacy Policy") {}
                        Text("·").foregroundStyle(.white.opacity(0.3))
                        Button("Terms") {}
                    }
                    .font(FlyFont.caption(11))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, FlySpacing.lg)
                    .padding(.bottom, FlySpacing.xxl)
                }
            }
        }
        .onAppear { appeared = true }
    }

    private var ctaLabel: String {
        switch selectedPlan {
        case .monthly:  return "Start 7-Day Free Trial"
        case .annual:   return "Start 7-Day Free Trial"
        case .lifetime: return "Get Lifetime Access"
        }
    }

    private let features: [PaywallFeature] = [
        PaywallFeature(icon: "sparkles", text: "Unlimited AI Chat & Analysis", highlight: true),
        PaywallFeature(icon: "arrow.2.squarepath", text: "Unlimited PDF Conversions"),
        PaywallFeature(icon: "signature", text: "Unlimited E-Signatures"),
        PaywallFeature(icon: "arrow.down.circle.fill", text: "Unlimited Compression"),
        PaywallFeature(icon: "doc.text.viewfinder", text: "Smart OCR & Text Extraction"),
        PaywallFeature(icon: "globe", text: "AI Translation (50+ languages)"),
        PaywallFeature(icon: "lock.shield.fill", text: "Face ID Encrypted Vault"),
        PaywallFeature(icon: "icloud.fill", text: "iCloud Sync across all devices"),
        PaywallFeature(icon: "square.grid.2x2.fill", text: "Widgets & Shortcuts"),
    ]
}

// MARK: - Feature Row

struct PaywallFeature {
    let icon: String
    let text: String
    var highlight: Bool = false
}

struct FeatureRow: View {
    let feature: PaywallFeature

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: feature.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(feature.highlight ? FlyColor.electricBlue : .white.opacity(0.8))
                .frame(width: 28)

            Text(feature.text)
                .font(FlyFont.body(15))
                .foregroundStyle(feature.highlight ? .white : .white.opacity(0.85))
                .fontWeight(feature.highlight ? .semibold : .regular)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(FlyColor.success)
        }
        .padding(.horizontal, FlySpacing.md)
        .padding(.vertical, 12)
        .background(.white.opacity(feature.highlight ? 0.1 : 0.04), in: RoundedRectangle(cornerRadius: FlyRadius.sm, style: .continuous))
        .overlay {
            if feature.highlight {
                RoundedRectangle(cornerRadius: FlyRadius.sm, style: .continuous)
                    .strokeBorder(FlyColor.electricBlue.opacity(0.4), lineWidth: 1)
            }
        }
    }
}

// MARK: - Plan Picker

struct PlanPicker: View {
    @Binding var selected: PremiumPaywall.Plan

    private let plans: [(plan: PremiumPaywall.Plan, price: String, sub: String, badge: String?)] = [
        (.monthly,  "$4.99/mo",  "Billed monthly",          nil),
        (.annual,   "$34.99/yr", "$2.92/month · Save 42%",  "Most Popular"),
        (.lifetime, "$149.99",   "One-time · Forever yours", "Best Value"),
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(plans, id: \.plan) { item in
                Button {
                    withAnimation(FlySpring.snappy) {
                        selected = item.plan
                        FlyHaptic.selection()
                    }
                } label: {
                    HStack {
                        // Radio
                        ZStack {
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 22, height: 22)

                            if selected == item.plan {
                                Circle()
                                    .fill(FlyColor.electricBlue)
                                    .frame(width: 12, height: 12)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .animation(FlySpring.snappy, value: selected)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.plan.rawValue)
                                .font(FlyFont.body(15))
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)

                            Text(item.sub)
                                .font(FlyFont.caption(12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.leading, 4)

                        Spacer()

                        if let badge = item.badge {
                            Text(badge)
                                .font(FlyFont.label(10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(FlyColor.electricBlue, in: Capsule())
                        }

                        Text(item.price)
                            .font(FlyFont.body(15))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.leading, 8)
                    }
                    .padding(FlySpacing.md)
                    .background(
                        selected == item.plan
                            ? FlyColor.electricBlue.opacity(0.2)
                            : .white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                            .strokeBorder(
                                selected == item.plan
                                    ? FlyColor.electricBlue
                                    : .white.opacity(0.12),
                                lineWidth: selected == item.plan ? 2 : 1
                            )
                    }
                    .animation(FlySpring.snappy, value: selected)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
