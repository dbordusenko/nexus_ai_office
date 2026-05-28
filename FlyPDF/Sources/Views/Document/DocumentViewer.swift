import SwiftUI
import PDFKit

// MARK: - Document Viewer

struct DocumentViewer: View {
    let document: FlyDocument
    @Environment(\.dismiss) private var dismiss
    @State private var showChrome = true
    @State private var showTools = false
    @State private var showAIChat = false
    @State private var currentPage = 1
    @State private var zoom: CGFloat = 1.0
    @State private var chromeHideTimer: Timer?
    @Namespace private var animation

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // PDF Content
            PDFViewWrapper(document: document, currentPage: $currentPage)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(FlySpring.snappy) {
                        showChrome.toggle()
                    }
                    if showChrome { scheduleHideChrome() }
                }

            // MARK: Top Bar (Chrome)
            if showChrome {
                VStack {
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }

            // MARK: Bottom Bar (Chrome)
            if showChrome {
                VStack {
                    Spacer()
                    bottomBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // MARK: AI Orb (always visible)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    AIOrb(document: document)
                        .padding(.trailing, FlySpacing.lg)
                        .padding(.bottom, showChrome ? 110 : 40)
                        .animation(FlySpring.standard, value: showChrome)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(!showChrome)
        .animation(FlySpring.snappy, value: showChrome)
        .sheet(isPresented: $showTools) {
            ToolsBottomSheet(document: document)
                .presentationDetents([.height(380), .medium])
                .presentationCornerRadius(FlyRadius.xl)
                .presentationDragIndicator(.visible)
        }
        .onAppear { scheduleHideChrome() }
        .onDisappear { chromeHideTimer?.invalidate() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Back
            Button {
                FlyHaptic.light()
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FlyColor.label)
                    .frame(width: 40, height: 40)
                    .flyGlass(cornerRadius: FlyRadius.md)
            }
            .buttonStyle(.flyPress)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(FlyFont.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(FlyColor.label)
                    .lineLimit(1)

                Text("\(document.pages) pages · \(document.formattedSize)")
                    .font(FlyFont.caption(11))
                    .foregroundStyle(FlyColor.secondaryLabel)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            HStack(spacing: 8) {
                Button {
                    FlyHaptic.light()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FlyColor.label)
                        .frame(width: 40, height: 40)
                        .flyGlass(cornerRadius: FlyRadius.md)
                }
                .buttonStyle(.flyPress)

                Button {
                    FlyHaptic.light()
                    showTools = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FlyColor.label)
                        .frame(width: 40, height: 40)
                        .flyGlass(cornerRadius: FlyRadius.md)
                }
                .buttonStyle(.flyPress)
            }
        }
        .padding(.horizontal, FlySpacing.md)
        .padding(.vertical, FlySpacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            // Page indicator
            Text("\(currentPage) / \(document.pages)")
                .font(FlyFont.caption())
                .fontWeight(.semibold)
                .foregroundStyle(FlyColor.secondaryLabel)
                .frame(width: 72)

            Spacer()

            // Page scrubber
            PageScrubber(current: $currentPage, total: document.pages)

            Spacer()

            // Zoom
            HStack(spacing: 8) {
                Button {
                    withAnimation(FlySpring.snappy) { zoom = max(0.5, zoom - 0.25) }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FlyColor.label)
                        .frame(width: 32, height: 32)
                        .flyGlass(cornerRadius: FlyRadius.sm)
                }

                Button {
                    withAnimation(FlySpring.snappy) { zoom = min(4.0, zoom + 0.25) }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FlyColor.label)
                        .frame(width: 32, height: 32)
                        .flyGlass(cornerRadius: FlyRadius.sm)
                }
            }
            .frame(width: 72)
        }
        .padding(.horizontal, FlySpacing.md)
        .padding(.vertical, FlySpacing.sm)
        .background(.ultraThinMaterial)
        .padding(.bottom, 20)
    }

    private func scheduleHideChrome() {
        chromeHideTimer?.invalidate()
        chromeHideTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            withAnimation(FlySpring.snappy) {
                showChrome = false
            }
        }
    }
}

// MARK: - PDFKit Wrapper

struct PDFViewWrapper: UIViewRepresentable {
    let document: FlyDocument
    @Binding var currentPage: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.usePageViewController(true, withViewOptions: nil)

        if let url = document.url, let pdfDoc = PDFDocument(url: url) {
            pdfView.document = pdfDoc
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: PDFViewWrapper

        init(_ parent: PDFViewWrapper) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let doc = pdfView.document,
                  let idx = doc.index(for: page) as Int?
            else { return }
            DispatchQueue.main.async {
                self.parent.currentPage = idx + 1
            }
        }
    }
}

// MARK: - Page Scrubber

struct PageScrubber: View {
    @Binding var current: Int
    let total: Int
    @State private var dragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(FlyColor.separator.opacity(0.5))
                    .frame(height: 4)

                // Fill
                Capsule()
                    .fill(FlyColor.brandGradient)
                    .frame(width: max(0, geo.size.width * progress), height: 4)

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: dragging ? 18 : 12, height: dragging ? 18 : 12)
                    .shadow(color: FlyColor.electricBlue.opacity(0.4), radius: 6)
                    .offset(x: max(0, geo.size.width * progress - (dragging ? 9 : 6)))
                    .animation(FlySpring.snappy, value: dragging)
            }
            .frame(height: 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragging = true
                        let pct = max(0, min(1, value.location.x / geo.size.width))
                        current = max(1, min(total, Int(pct * CGFloat(total)) + 1))
                    }
                    .onEnded { _ in
                        dragging = false
                        FlyHaptic.selection()
                    }
            )
        }
        .frame(height: 20)
        .frame(maxWidth: 200)
    }

    private var progress: CGFloat {
        guard total > 1 else { return 1 }
        return CGFloat(current - 1) / CGFloat(total - 1)
    }
}

// MARK: - Tools Bottom Sheet

struct ToolsBottomSheet: View {
    let document: FlyDocument

    private let tools: [(icon: String, label: String, gradient: LinearGradient)] = [
        ("pencil.tip", "Annotate", LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0055D4")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("signature", "Sign", LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#1E8C3A")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("arrow.down.circle.fill", "Compress", LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#3A37B4")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("arrow.2.squarepath", "Convert", LinearGradient(colors: [Color(hex: "#AF52DE"), Color(hex: "#7B2AB6")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("globe", "Translate", LinearGradient(colors: [Color(hex: "#32ADE6"), Color(hex: "#0076A3")], startPoint: .topLeading, endPoint: .bottomTrailing)),
        ("crop", "Crop Pages", LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#CC7A00")], startPoint: .topLeading, endPoint: .bottomTrailing)),
    ]

    var body: some View {
        VStack(spacing: FlySpacing.lg) {
            // Header
            HStack {
                Text("Document Tools")
                    .font(FlyFont.subheading())
                    .foregroundStyle(FlyColor.label)
                Spacer()
                Text("\(document.pages) pages")
                    .font(FlyFont.caption())
                    .foregroundStyle(FlyColor.secondaryLabel)
            }
            .padding(.horizontal, FlySpacing.lg)
            .padding(.top, FlySpacing.sm)

            // Tools grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(tools.indices, id: \.self) { i in
                    Button {
                        FlyHaptic.medium()
                    } label: {
                        VStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(tools[i].gradient)
                                .frame(height: 60)
                                .overlay {
                                    Image(systemName: tools[i].icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                                .flyShadowSoft()

                            Text(tools[i].label)
                                .font(FlyFont.caption(12))
                                .foregroundStyle(FlyColor.secondaryLabel)
                        }
                    }
                    .buttonStyle(.flyPress(scale: 0.93))
                }
            }
            .padding(.horizontal, FlySpacing.lg)

            Spacer()
        }
    }
}
