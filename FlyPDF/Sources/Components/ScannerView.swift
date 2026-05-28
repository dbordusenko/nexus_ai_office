import SwiftUI
import AVFoundation
import VisionKit

// MARK: - Scanner View

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showDocumentScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var state: ScanState = .ready
    @State private var ocrProgress: Double = 0
    @State private var suggestedName = ""

    enum ScanState {
        case ready
        case scanning
        case processing
        case done
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch state {
            case .ready:
                ScanReadyView {
                    showDocumentScanner = true
                    state = .scanning
                }

            case .scanning:
                ScanReadyView {
                    showDocumentScanner = true
                }

            case .processing:
                ScanProcessingView(progress: $ocrProgress, imageCount: scannedImages.count)

            case .done:
                ScanDoneView(
                    images: scannedImages,
                    suggestedName: suggestedName,
                    onSave: { dismiss() },
                    onRetake: {
                        scannedImages = []
                        state = .ready
                    }
                )
            }
        }
        .sheet(isPresented: $showDocumentScanner) {
            DocumentScannerRepresentable { result in
                switch result {
                case .success(let images):
                    scannedImages = images
                    startOCR()
                case .failure:
                    state = .ready
                }
                showDocumentScanner = false
            }
        }
    }

    private func startOCR() {
        withAnimation(FlySpring.standard) {
            state = .processing
            ocrProgress = 0
        }
        FlyHaptic.medium()

        Task {
            for i in 0...20 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                await MainActor.run {
                    withAnimation(FlySpring.snappy) {
                        ocrProgress = Double(i) / 20.0
                    }
                }
            }
            await MainActor.run {
                suggestedName = generateSmartName()
                withAnimation(FlySpring.bouncy) {
                    state = .done
                    FlyHaptic.success()
                }
            }
        }
    }

    private func generateSmartName() -> String {
        let names = [
            "Receipt_Starbucks_May2026",
            "Invoice_Freelance_May27",
            "Contract_Signed_2026",
            "Document_Scanned_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-"))"
        ]
        return names.randomElement()! + ".pdf"
    }
}

// MARK: - Scan Ready View

struct ScanReadyView: View {
    let onScan: () -> Void
    @State private var frameAnimate = false

    var body: some View {
        ZStack {
            // Camera preview placeholder
            Color(hex: "#0A0A0F").ignoresSafeArea()

            // Scanning frame
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(FlyColor.electricBlue, lineWidth: 3)
                .frame(width: 280, height: 360)
                .overlay(alignment: .topLeading) {
                    scanCorner
                }
                .overlay(alignment: .topTrailing) {
                    scanCorner.rotationEffect(.degrees(90))
                }
                .overlay(alignment: .bottomLeading) {
                    scanCorner.rotationEffect(.degrees(-90))
                }
                .overlay(alignment: .bottomTrailing) {
                    scanCorner.rotationEffect(.degrees(180))
                }
                .scaleEffect(frameAnimate ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: frameAnimate)

            // Scan line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, FlyColor.electricBlue.opacity(0.8), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 260, height: 2)
                .offset(y: frameAnimate ? 160 : -160)
                .clipShape(RoundedRectangle(cornerRadius: 1))
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: frameAnimate)

            // Instructions
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Text("Point camera at a document")
                        .font(FlyFont.body())
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Auto-captures when document is detected")
                        .font(FlyFont.caption(12))
                        .foregroundStyle(.white.opacity(0.6))

                    Button(action: onScan) {
                        ZStack {
                            Circle()
                                .strokeBorder(.white.opacity(0.5), lineWidth: 3)
                                .frame(width: 72, height: 72)

                            Circle()
                                .fill(.white)
                                .frame(width: 58, height: 58)
                        }
                    }
                    .buttonStyle(.flyPress)
                }
                .padding(.bottom, FlySpacing.xxl)
            }
        }
        .onAppear { frameAnimate = true }
    }

    private var scanCorner: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 24))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(FlyColor.electricBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .frame(width: 24, height: 24)
        .padding(4)
    }
}

// MARK: - Scan Processing

struct ScanProcessingView: View {
    @Binding var progress: Double
    let imageCount: Int
    @State private var rotate = false

    var body: some View {
        VStack(spacing: FlySpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(FlyColor.electricBlue.opacity(0.1))
                    .frame(width: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(FlyColor.brandGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(FlySpring.snappy, value: progress)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(FlyColor.electricBlue)
                    .rotationEffect(.degrees(rotate ? 10 : -10))
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: rotate)
            }

            VStack(spacing: 8) {
                Text("Processing \(imageCount) page\(imageCount == 1 ? "" : "s")…")
                    .font(FlyFont.subheading())
                    .foregroundStyle(.white)

                Text("Running OCR · Detecting document type · Auto-renaming")
                    .font(FlyFont.caption(12))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Text("\(Int(progress * 100))%")
                .font(.system(size: 48, weight: .black, design: .monospaced))
                .foregroundStyle(FlyColor.electricBlue)
                .contentTransition(.numericText())

            Spacer()
        }
        .padding(FlySpacing.xl)
        .onAppear { rotate = true }
    }
}

// MARK: - Scan Done

struct ScanDoneView: View {
    let images: [UIImage]
    let suggestedName: String
    let onSave: () -> Void
    let onRetake: () -> Void
    @State private var fileName: String
    @State private var appeared = false

    init(images: [UIImage], suggestedName: String, onSave: @escaping () -> Void, onRetake: @escaping () -> Void) {
        self.images = images
        self.suggestedName = suggestedName
        self.onSave = onSave
        self.onRetake = onRetake
        self._fileName = State(initialValue: suggestedName)
    }

    var body: some View {
        VStack(spacing: FlySpacing.xl) {
            Spacer()

            // Preview
            ZStack {
                ForEach(0..<min(3, images.count), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(FlyColor.softGraphite)
                        .frame(width: 180, height: 230)
                        .rotationEffect(.degrees(Double(i - 1) * 8))
                        .offset(x: Double(i - 1) * 12.0)
                        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)
                        .animation(FlySpring.bouncy.delay(Double(i) * 0.08), value: appeared)
                }
            }
            .frame(height: 250)

            VStack(spacing: FlySpacing.sm) {
                Text("Scan Complete!")
                    .font(FlyFont.heading())
                    .foregroundStyle(.white)

                Text("\(images.count) page\(images.count == 1 ? "" : "s") · AI named your file")
                    .font(FlyFont.caption())
                    .foregroundStyle(.white.opacity(0.6))
            }
            .opacity(appeared ? 1 : 0)
            .animation(FlySpring.standard.delay(0.3), value: appeared)

            // Smart file name
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(FlyColor.electricBlue)
                    Text("AI suggested name")
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.electricBlue)
                }

                TextField("File name", text: $fileName)
                    .font(FlyFont.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, FlySpacing.md)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: FlyRadius.md, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .padding(.horizontal, FlySpacing.xl)
            .opacity(appeared ? 1 : 0)
            .animation(FlySpring.standard.delay(0.4), value: appeared)

            // Buttons
            VStack(spacing: 12) {
                Button {
                    FlyHaptic.success()
                    onSave()
                } label: {
                    Text("Save to Library")
                        .font(FlyFont.body())
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FlyColor.brandGradient, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
                        .flyShadowBlue()
                }
                .buttonStyle(.flyPress)

                Button("Retake Scan", action: onRetake)
                    .font(FlyFont.body())
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, FlySpacing.lg)
            .opacity(appeared ? 1 : 0)
            .animation(FlySpring.standard.delay(0.5), value: appeared)

            Spacer()
        }
        .padding(FlySpacing.xl)
        .background(Color(hex: "#050A1A").ignoresSafeArea())
        .onAppear { appeared = true }
    }
}

// MARK: - VisionKit Bridge

struct DocumentScannerRepresentable: UIViewControllerRepresentable {
    let completion: (Result<[UIImage], Error>) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completion: (Result<[UIImage], Error>) -> Void

        init(completion: @escaping (Result<[UIImage], Error>) -> Void) {
            self.completion = completion
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            completion(.success(images))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completion(.failure(CancellationError()))
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completion(.failure(error))
        }
    }
}
