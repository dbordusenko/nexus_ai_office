import SwiftUI

// MARK: - Conversion View

struct ConversionView: View {
    @Environment(\.dismiss) private var dismiss
    let sourceDocument: FlyDocument?
    @State private var selectedFormat: ConversionFormat?
    @State private var state: ConversionState = .selectFormat

    enum ConversionState {
        case selectFormat
        case processing(Double)
        case done(FlyDocument)
        case error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FlyColor.secondaryBg.ignoresSafeArea()

                switch state {
                case .selectFormat:
                    FormatSelectionView(
                        document: sourceDocument,
                        onSelect: { format in
                            selectedFormat = format
                            startConversion(to: format)
                        }
                    )

                case .processing(let progress):
                    ConversionProcessingView(
                        progress: progress,
                        format: selectedFormat,
                        document: sourceDocument
                    )

                case .done(let result):
                    ConversionDoneView(result: result) {
                        dismiss()
                    }

                case .error(let msg):
                    ConversionErrorView(message: msg) {
                        state = .selectFormat
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FlyColor.label)
                            .frame(width: 32, height: 32)
                            .flyGlass(cornerRadius: FlyRadius.sm)
                    }
                    .buttonStyle(.flyPress)
                }
            }
        }
    }

    private func startConversion(to format: ConversionFormat) {
        withAnimation(FlySpring.standard) {
            state = .processing(0)
        }
        FlyHaptic.medium()

        // Simulate progressive conversion
        Task {
            let steps: [Double] = [0.08, 0.22, 0.41, 0.58, 0.73, 0.88, 0.95, 1.0]
            for step in steps {
                try? await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run {
                    withAnimation(FlySpring.snappy) {
                        state = .processing(step)
                    }
                }
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run {
                let result = FlyDocument(
                    name: (sourceDocument?.name.replacingOccurrences(of: ".pdf", with: "") ?? "Document") + format.fileExtension,
                    pages: sourceDocument?.pages ?? 1,
                    sizeBytes: Int(Double(sourceDocument?.sizeBytes ?? 500_000) * 1.2),
                    type: .other,
                    thumbnailColor: format.color
                )
                withAnimation(FlySpring.bouncy) {
                    state = .done(result)
                    FlyHaptic.success()
                }
            }
        }
    }
}

// MARK: - Format Selection

struct FormatSelectionView: View {
    let document: FlyDocument?
    let onSelect: (ConversionFormat) -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: FlySpacing.xl) {
                // Source card
                if let doc = document {
                    VStack(spacing: FlySpacing.sm) {
                        Text("Converting from")
                            .font(FlyFont.caption())
                            .foregroundStyle(FlyColor.secondaryLabel)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        HStack(spacing: 12) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Color(hex: "#FF3B30"))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(doc.name)
                                    .font(FlyFont.body())
                                    .fontWeight(.medium)
                                    .foregroundStyle(FlyColor.label)
                                    .lineLimit(1)

                                Text("\(doc.pages) pages · \(doc.formattedSize)")
                                    .font(FlyFont.caption(12))
                                    .foregroundStyle(FlyColor.secondaryLabel)
                            }
                            Spacer()
                        }
                        .padding(FlySpacing.md)
                        .flyGlass(cornerRadius: FlyRadius.lg)
                        .flyShadowSoft()
                    }
                    .padding(.horizontal, FlySpacing.lg)
                }

                // Format grid
                VStack(spacing: FlySpacing.md) {
                    Text("Choose output format")
                        .font(FlyFont.subheading())
                        .foregroundStyle(FlyColor.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, FlySpacing.lg)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 14
                    ) {
                        ForEach(Array(ConversionFormat.allCases.enumerated()), id: \.element) { i, format in
                            FormatCard(format: format, onSelect: onSelect)
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared ? 1 : 0.9)
                                .animation(FlySpring.bouncy.delay(Double(i) * 0.06), value: appeared)
                        }
                    }
                    .padding(.horizontal, FlySpacing.lg)
                }

                Color.clear.frame(height: 40)
            }
            .padding(.top, FlySpacing.lg)
        }
        .onAppear { appeared = true }
    }
}

struct FormatCard: View {
    let format: ConversionFormat
    let onSelect: (ConversionFormat) -> Void

    var body: some View {
        Button {
            onSelect(format)
            FlyHaptic.medium()
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(format.color.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: format.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(format.color)
                }

                VStack(spacing: 3) {
                    Text(format.rawValue)
                        .font(FlyFont.body(15))
                        .fontWeight(.semibold)
                        .foregroundStyle(FlyColor.label)

                    Text(format.fileExtension)
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FlySpacing.lg)
            .background(FlyColor.background, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous)
                    .strokeBorder(FlyColor.separator.opacity(0.4), lineWidth: 0.5)
            }
            .flyShadowCard()
        }
        .buttonStyle(.flyPress(scale: 0.95))
    }
}

// MARK: - Processing View

struct ConversionProcessingView: View {
    let progress: Double
    let format: ConversionFormat?
    let document: FlyDocument?
    @State private var paperAngle: Double = 0
    @State private var orbScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: FlySpacing.xl) {
            Spacer()

            // Flying papers animation
            ZStack {
                // Orbit rings
                Circle()
                    .strokeBorder(
                        FlyColor.electricBlue.opacity(0.12),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                    )
                    .frame(width: 200)
                    .rotationEffect(.degrees(paperAngle))

                Circle()
                    .strokeBorder(
                        FlyColor.violet.opacity(0.10),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 6])
                    )
                    .frame(width: 260)
                    .rotationEffect(.degrees(-paperAngle * 0.7))

                // Orbiting source PDF
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "#FF3B30").opacity(0.9))
                    .frame(width: 42, height: 54)
                    .overlay {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color(hex: "#FF3B30").opacity(0.4), radius: 8)
                    .offset(x: cos(paperAngle * .pi / 180) * 100,
                            y: sin(paperAngle * .pi / 180) * 100)

                // Orbiting target format
                if let fmt = format {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(fmt.color.opacity(0.9))
                        .frame(width: 42, height: 54)
                        .overlay {
                            Image(systemName: fmt.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: fmt.color.opacity(0.4), radius: 8)
                        .offset(x: cos((paperAngle + 180) * .pi / 180) * 100,
                                y: sin((paperAngle + 180) * .pi / 180) * 100)
                }

                // Central orb
                Circle()
                    .fill(FlyColor.brandGradient)
                    .frame(width: 72)
                    .scaleEffect(orbScale)
                    .shadow(color: FlyColor.electricBlue.opacity(0.5), radius: 20, y: 6)
                    .overlay {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(-paperAngle))
                    }
            }
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    paperAngle = 360
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    orbScale = 1.08
                }
            }

            VStack(spacing: 10) {
                Text("Converting…")
                    .font(FlyFont.subheading())
                    .foregroundStyle(FlyColor.label)

                if let doc = document, let fmt = format {
                    Text("\(doc.name) → \(fmt.rawValue)")
                        .font(FlyFont.caption())
                        .foregroundStyle(FlyColor.secondaryLabel)
                        .lineLimit(1)
                }
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FlyColor.separator.opacity(0.4))
                            .frame(height: 6)

                        Capsule()
                            .fill(FlyColor.brandGradient)
                            .frame(width: max(0, geo.size.width * progress), height: 6)
                            .animation(FlySpring.snappy, value: progress)
                    }
                }
                .frame(height: 6)

                Text("\(Int(progress * 100))%")
                    .font(FlyFont.label(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(FlyColor.electricBlue)
                    .monospacedDigit()
            }
            .padding(.horizontal, FlySpacing.xxl)

            Spacer()
        }
        .padding(FlySpacing.xl)
    }
}

// MARK: - Done View

struct ConversionDoneView: View {
    let result: FlyDocument
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var confettiParticles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            // Confetti
            ForEach(confettiParticles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size)
                    .offset(p.offset)
                    .opacity(p.opacity)
            }

            VStack(spacing: FlySpacing.xl) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(FlyColor.success.opacity(0.12))
                        .frame(width: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(FlyColor.success)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .animation(FlySpring.bouncy.delay(0.1), value: appeared)
                }

                VStack(spacing: 8) {
                    Text("Conversion Complete!")
                        .font(FlyFont.heading())
                        .foregroundStyle(FlyColor.label)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(FlySpring.standard.delay(0.2), value: appeared)

                    Text(result.name)
                        .font(FlyFont.body())
                        .foregroundStyle(FlyColor.secondaryLabel)
                        .lineLimit(1)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(FlySpring.standard.delay(0.3), value: appeared)
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        FlyHaptic.medium()
                    } label: {
                        Label("Share File", systemImage: "square.and.arrow.up")
                            .font(FlyFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FlyColor.brandGradient, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
                            .flyShadowBlue()
                    }
                    .buttonStyle(.flyPress)

                    Button {
                        FlyHaptic.light()
                        onDismiss()
                    } label: {
                        Text("Save to Library")
                            .font(FlyFont.body())
                            .fontWeight(.medium)
                            .foregroundStyle(FlyColor.label)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .flyGlass(cornerRadius: FlyRadius.lg)
                    }
                    .buttonStyle(.flyPress)
                }
                .padding(.horizontal, FlySpacing.lg)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(FlySpring.standard.delay(0.4), value: appeared)

                Spacer()
            }
        }
        .onAppear {
            appeared = true
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [FlyColor.electricBlue, FlyColor.violet, FlyColor.success, FlyColor.warning]
        confettiParticles = (0..<20).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                offset: CGSize(
                    width: CGFloat.random(in: -160...160),
                    height: CGFloat.random(in: -300...100)
                ),
                opacity: Double.random(in: 0.6...1.0)
            )
        }
        withAnimation(.easeOut(duration: 1.2)) {
            confettiParticles = confettiParticles.map {
                var p = $0
                p.offset.height += 200
                p.opacity = 0
                return p
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}

// MARK: - Error View

struct ConversionErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: FlySpacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(FlyColor.error)

            VStack(spacing: 8) {
                Text("Conversion Failed")
                    .font(FlyFont.heading())
                    .foregroundStyle(FlyColor.label)

                Text(message)
                    .font(FlyFont.body())
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            Button("Try Again", action: onRetry)
                .font(FlyFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(FlyColor.brandGradient, in: Capsule())
                .buttonStyle(.flyPress)

            Spacer()
        }
        .padding(FlySpacing.xl)
    }
}
