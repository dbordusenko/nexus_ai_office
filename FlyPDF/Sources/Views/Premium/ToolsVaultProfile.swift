import SwiftUI

// MARK: - Tools View

struct ToolsView: View {
    @State private var showConversion = false
    @State private var appeared = false

    private let toolGroups: [(title: String, tools: [(name: String, icon: String, gradient: LinearGradient, isPremium: Bool)])] = [
        (
            title: "AI Tools",
            tools: [
                ("Summarize PDF",    "text.alignleft",           LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Chat with PDF",    "sparkles",                  LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#AF52DE")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Analyze Contract", "doc.badge.clock",           LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0055D4")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("Translate PDF",    "globe",                     LinearGradient(colors: [Color(hex: "#32ADE6"), Color(hex: "#0076A3")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("Extract Tables",   "tablecells.badge.ellipsis", LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#217346")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("Voice Summary",    "waveform.circle.fill",      LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#CC7A00")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
            ]
        ),
        (
            title: "Edit & Organize",
            tools: [
                ("Merge PDFs",       "arrow.triangle.merge",      LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0055D4")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Split PDF",        "scissors",                  LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#3A37B4")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Compress PDF",     "arrow.down.circle.fill",    LinearGradient(colors: [Color(hex: "#AF52DE"), Color(hex: "#7B2AB6")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Reorder Pages",    "arrow.up.arrow.down",       LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#1E8C3A")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Crop Pages",       "crop",                      LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#CC7A00")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Watermark",        "seal.fill",                 LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#CC3333")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
            ]
        ),
        (
            title: "Convert",
            tools: [
                ("PDF → Word",       "doc.text.fill",             LinearGradient(colors: [Color(hex: "#2B7CD3"), Color(hex: "#1B5FA6")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("PDF → Excel",      "tablecells.fill",           LinearGradient(colors: [Color(hex: "#217346"), Color(hex: "#155724")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("PDF → PowerPoint", "rectangle.on.rectangle.fill", LinearGradient(colors: [Color(hex: "#D24726"), Color(hex: "#A3341B")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("PDF → Images",     "photo.stack.fill",          LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#3A37B4")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Word → PDF",       "doc.fill",                  LinearGradient(colors: [Color(hex: "#FF3B30"), Color(hex: "#CC2A22")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Images → PDF",     "photo.badge.plus",          LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#CC7A00")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
            ]
        ),
        (
            title: "Security",
            tools: [
                ("Sign PDF",         "signature",                 LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#1E8C3A")], startPoint: .topLeading, endPoint: .bottomTrailing), false),
                ("Password Protect", "lock.fill",                 LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0055D4")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("Remove Password",  "lock.open.fill",            LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#3A37B4")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
                ("Redact Content",   "eye.slash.fill",            LinearGradient(colors: [Color(hex: "#1C1C1E"), Color(hex: "#3A3A3C")], startPoint: .topLeading, endPoint: .bottomTrailing), true),
            ]
        ),
    ]

    var body: some View {
        ZStack {
            FlyColor.secondaryBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    Text("Tools")
                        .font(FlyFont.display(34))
                        .foregroundStyle(FlyColor.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, FlySpacing.lg)
                        .padding(.top, FlySpacing.sm)
                        .padding(.bottom, FlySpacing.xl)

                    ForEach(toolGroups.indices, id: \.self) { gi in
                        let group = toolGroups[gi]

                        VStack(alignment: .leading, spacing: 14) {
                            Text(group.title)
                                .font(FlyFont.label())
                                .foregroundStyle(FlyColor.secondaryLabel)
                                .textCase(.uppercase)
                                .tracking(0.6)
                                .padding(.horizontal, FlySpacing.lg)

                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                spacing: 12
                            ) {
                                ForEach(group.tools.indices, id: \.self) { ti in
                                    let tool = group.tools[ti]
                                    ToolCard(
                                        name: tool.name,
                                        icon: tool.icon,
                                        gradient: tool.gradient,
                                        isPremium: tool.isPremium
                                    )
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 16)
                                    .animation(FlySpring.standard.delay(Double(gi * 6 + ti) * 0.025), value: appeared)
                                }
                            }
                            .padding(.horizontal, FlySpacing.lg)
                        }
                        .padding(.bottom, FlySpacing.xl)
                    }

                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear { appeared = true }
    }
}

struct ToolCard: View {
    let name: String
    let icon: String
    let gradient: LinearGradient
    let isPremium: Bool

    var body: some View {
        Button {
            FlyHaptic.medium()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(gradient)
                        .frame(width: 46, height: 46)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .flyShadowSoft()

                Text(name)
                    .font(FlyFont.caption(13))
                    .fontWeight(.medium)
                    .foregroundStyle(FlyColor.label)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isPremium {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(FlyColor.warning)
                }
            }
            .padding(FlySpacing.sm + 4)
            .background(FlyColor.background, in: RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                    .strokeBorder(FlyColor.separator.opacity(0.4), lineWidth: 0.5)
            }
            .flyShadowCard()
        }
        .buttonStyle(.flyPress(scale: 0.97))
    }
}

// MARK: - Vault View

struct VaultView: View {
    @State private var isUnlocked = false
    @State private var vaultDocs: [FlyDocument] = []

    var body: some View {
        ZStack {
            FlyColor.secondaryBg.ignoresSafeArea()

            if isUnlocked {
                VaultUnlockedView(documents: vaultDocs)
            } else {
                VaultLockedView {
                    withAnimation(FlySpring.bouncy) {
                        isUnlocked = true
                        FlyHaptic.success()
                    }
                }
            }
        }
    }
}

struct VaultLockedView: View {
    let onUnlock: () -> Void
    @State private var animate = false

    var body: some View {
        VStack(spacing: FlySpacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FlyColor.electricBlue.opacity(0.08))
                    .frame(width: 160)

                Circle()
                    .fill(FlyColor.electricBlue.opacity(0.05))
                    .frame(width: 220)
                    .scaleEffect(animate ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(FlyColor.brandGradient)
                    .scaleEffect(animate ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }

            VStack(spacing: 10) {
                Text("Your Secure Vault")
                    .font(FlyFont.heading())
                    .foregroundStyle(FlyColor.label)

                Text("Protected by Face ID.\nYour sensitive documents, always private.")
                    .font(FlyFont.body())
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                onUnlock()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "faceid")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Unlock with Face ID")
                        .font(FlyFont.body())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, FlySpacing.xl)
                .padding(.vertical, 16)
                .background(FlyColor.brandGradient, in: Capsule())
                .flyShadowBlue()
            }
            .buttonStyle(.flyPress)

            Spacer()
        }
        .padding(FlySpacing.xl)
        .onAppear { animate = true }
    }
}

struct VaultUnlockedView: View {
    let documents: [FlyDocument]

    var body: some View {
        VStack(spacing: FlySpacing.lg) {
            HStack {
                Text("Vault")
                    .font(FlyFont.display(34))
                    .foregroundStyle(FlyColor.label)

                Spacer()

                Image(systemName: "lock.open.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(FlyColor.success)
                    .padding(8)
                    .background(FlyColor.success.opacity(0.12), in: Circle())
            }
            .padding(.horizontal, FlySpacing.lg)
            .padding(.top, FlySpacing.sm)

            if documents.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "lock.badge.plus")
                        .font(.system(size: 52))
                        .foregroundStyle(FlyColor.electricBlue)
                    Text("Add sensitive documents here\nfor Face ID protection.")
                        .font(FlyFont.body())
                        .foregroundStyle(FlyColor.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(documents) { doc in
                        DocumentRowCard(document: doc, onTap: {})
                            .padding(.horizontal, FlySpacing.lg)
                    }
                }
            }
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            FlyColor.secondaryBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: FlySpacing.xl) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(FlyColor.brandGradient)
                                .frame(width: 80, height: 80)
                            Text("D")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .flyShadowBlue()

                        VStack(spacing: 4) {
                            Text("Dmytro")
                                .font(FlyFont.heading(24))
                                .foregroundStyle(FlyColor.label)

                            Text(appState.isPremium ? "FlyPDF Pro" : "Free Plan")
                                .font(FlyFont.caption())
                                .foregroundStyle(appState.isPremium ? FlyColor.electricBlue : FlyColor.secondaryLabel)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    appState.isPremium
                                        ? FlyColor.electricBlue.opacity(0.12)
                                        : FlyColor.secondaryBg,
                                    in: Capsule()
                                )
                        }
                    }
                    .padding(.top, FlySpacing.xl)

                    // Upgrade banner (if free)
                    if !appState.isPremium {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Upgrade to Pro")
                                        .font(FlyFont.body())
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    Text("Unlock unlimited AI + conversions")
                                        .font(FlyFont.caption(12))
                                        .foregroundStyle(.white.opacity(0.8))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(FlySpacing.md)
                            .background(FlyColor.brandGradient, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
                            .flyShadowBlue()
                        }
                        .buttonStyle(.flyPress)
                        .padding(.horizontal, FlySpacing.lg)
                    }

                    // Settings sections
                    VStack(spacing: 2) {
                        SettingsSection(title: "General") {
                            SettingsRow(icon: "bell.fill", label: "Notifications", color: FlyColor.error)
                            SettingsRow(icon: "moon.fill", label: "Appearance", color: FlyColor.graphite)
                            SettingsRow(icon: "icloud.fill", label: "iCloud Sync", color: FlyColor.electricBlue)
                        }

                        SettingsSection(title: "AI") {
                            SettingsRow(icon: "sparkles", label: "AI Credits", color: FlyColor.violet)
                            SettingsRow(icon: "globe", label: "Translation Language", color: FlyColor.info)
                        }

                        SettingsSection(title: "Support") {
                            SettingsRow(icon: "questionmark.circle.fill", label: "Help & FAQ", color: FlyColor.success)
                            SettingsRow(icon: "star.fill", label: "Rate FlyPDF", color: FlyColor.warning)
                            SettingsRow(icon: "envelope.fill", label: "Contact Support", color: FlyColor.electricBlue)
                        }
                    }
                    .padding(.horizontal, FlySpacing.lg)

                    Text("FlyPDF v1.0.0 · Made with ✈️")
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.tertiaryLabel)
                        .padding(.bottom, 100)
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showPaywall) {
            PremiumPaywall()
                .presentationCornerRadius(FlyRadius.xl)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(FlyFont.label())
                .foregroundStyle(FlyColor.secondaryLabel)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, FlySpacing.md)
                .padding(.vertical, FlySpacing.sm)

            VStack(spacing: 0) {
                content
            }
            .background(FlyColor.background, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous)
                    .strokeBorder(FlyColor.separator.opacity(0.4), lineWidth: 0.5)
            }
            .flyShadowCard()
        }
        .padding(.bottom, FlySpacing.sm)
    }
}

struct SettingsRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Button {
            FlyHaptic.selection()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(label)
                    .font(FlyFont.body())
                    .foregroundStyle(FlyColor.label)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FlyColor.tertiaryLabel)
            }
            .padding(.horizontal, FlySpacing.md)
            .padding(.vertical, 13)
        }
        .buttonStyle(.flyPress(scale: 0.99))
    }
}
