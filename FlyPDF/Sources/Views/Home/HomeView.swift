import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    var namespace: Namespace.ID

    @State private var fabExpanded = false
    @State private var searchText = ""
    @State private var selectedDocument: FlyDocument?
    @State private var showSearch = false
    @State private var headerVisible = true
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack {
            FlyColor.secondaryBg.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // Spacer for top safe area
                    Color.clear.frame(height: 8)

                    // MARK: Header
                    HomeHeader(showSearch: $showSearch)
                        .padding(.horizontal, FlySpacing.lg)
                        .padding(.bottom, FlySpacing.lg)

                    // MARK: AI Suggestions
                    if !appState.documents.isEmpty {
                        AISmartSuggestionsStrip()
                            .padding(.bottom, FlySpacing.xl)
                    }

                    // MARK: Quick Actions
                    QuickActionsSection()
                        .padding(.bottom, FlySpacing.xl)

                    // MARK: Recent Documents
                    if appState.documents.isEmpty {
                        EmptyDocumentsState()
                            .padding(.top, FlySpacing.xxl)
                    } else {
                        RecentDocumentsSection(
                            documents: appState.documents,
                            namespace: namespace,
                            selectedDocument: $selectedDocument
                        )
                    }

                    // Bottom padding for tab bar
                    Color.clear.frame(height: 110)
                }
            }
            .scrollIndicators(.hidden)
            .refreshable {
                try? await Task.sleep(nanoseconds: 800_000_000)
            }

            // MARK: FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(expanded: $fabExpanded)
                        .padding(.trailing, FlySpacing.lg)
                        .padding(.bottom, 96)
                }
            }

            // MARK: Processing Overlay
            if let task = appState.processingTask {
                ProcessingBanner(task: task)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(FlySpring.standard, value: appState.processingTask != nil)
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedDocument) { doc in
            DocumentViewer(document: doc)
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
                .presentationDetents([.large])
                .presentationCornerRadius(FlyRadius.xl)
        }
    }
}

// MARK: - Home Header

struct HomeHeader: View {
    @Binding var showSearch: Bool
    @State private var appeared = false

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(FlyFont.caption())
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 6)
                    .animation(FlySpring.standard.delay(0.1), value: appeared)

                Text("FlyPDF")
                    .font(FlyFont.display(34, weight: .black))
                    .foregroundStyle(FlyColor.label)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(FlySpring.standard, value: appeared)
            }

            Spacer()

            HStack(spacing: 10) {
                // Search
                Button {
                    showSearch = true
                    FlyHaptic.light()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(FlyColor.label)
                        .frame(width: 42, height: 42)
                        .flyGlass(cornerRadius: FlyRadius.md)
                }
                .buttonStyle(.flyPress)
                .opacity(appeared ? 1 : 0)
                .animation(FlySpring.standard.delay(0.2), value: appeared)

                // Avatar
                Button {
                    // Profile
                } label: {
                    ZStack {
                        Circle()
                            .fill(FlyColor.brandGradient)
                            .frame(width: 42, height: 42)
                        Text("D")
                            .font(FlyFont.caption())
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.flyPress)
                .opacity(appeared ? 1 : 0)
                .animation(FlySpring.standard.delay(0.25), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - AI Smart Suggestions Strip

struct AISmartSuggestionsStrip: View {
    let suggestions = AISuggestion.samples
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(FlyColor.electricBlue)

                Text("AI Suggestions")
                    .font(FlyFont.label())
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }
            .padding(.horizontal, FlySpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { i, suggestion in
                        AISuggestionChip(suggestion: suggestion)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : 20)
                            .animation(FlySpring.standard.delay(Double(i) * 0.07), value: appeared)
                    }
                }
                .padding(.horizontal, FlySpacing.lg)
            }
        }
        .onAppear { appeared = true }
    }
}

struct AISuggestionChip: View {
    let suggestion: AISuggestion

    var body: some View {
        Button {
            FlyHaptic.light()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(suggestion.accentColor)
                    .frame(width: 30, height: 30)
                    .background(suggestion.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.text)
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.label)
                        .lineLimit(1)

                    Text(suggestion.actionLabel)
                        .font(FlyFont.label(11))
                        .foregroundStyle(suggestion.accentColor)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(FlyColor.silver)
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .flyGlass(cornerRadius: FlyRadius.md)
            .flyShadowSoft()
        }
        .buttonStyle(.flyPress(scale: 0.97))
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    let actions = QuickAction.all
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(FlyFont.subheading())
                .foregroundStyle(FlyColor.label)
                .padding(.horizontal, FlySpacing.lg)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4),
                spacing: 16
            ) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { i, action in
                    QuickActionButton(action: action)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .animation(FlySpring.bouncy.delay(Double(i) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, FlySpacing.lg)
        }
        .onAppear { appeared = true }
    }
}

struct QuickActionButton: View {
    let action: QuickAction

    var body: some View {
        Button {
            FlyHaptic.medium()
        } label: {
            VStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(action.gradient)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: action.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .flyShadowSoft()
                    .overlay(alignment: .topTrailing) {
                        if action.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(FlyColor.warning, in: Circle())
                                .offset(x: 4, y: -4)
                        }
                    }

                Text(action.name)
                    .font(FlyFont.caption(11))
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.flyPress(scale: 0.92))
    }
}

// MARK: - Recent Documents Section

struct RecentDocumentsSection: View {
    let documents: [FlyDocument]
    var namespace: Namespace.ID
    @Binding var selectedDocument: FlyDocument?
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent")
                    .font(FlyFont.subheading())
                    .foregroundStyle(FlyColor.label)

                Spacer()

                Button("See All") {
                    FlyHaptic.selection()
                }
                .font(FlyFont.body(15))
                .foregroundStyle(FlyColor.electricBlue)
            }
            .padding(.horizontal, FlySpacing.lg)

            LazyVStack(spacing: 10) {
                ForEach(Array(documents.enumerated()), id: \.element.id) { i, doc in
                    DocumentRowCard(document: doc) {
                        selectedDocument = doc
                        FlyHaptic.light()
                    }
                    .padding(.horizontal, FlySpacing.lg)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : 30)
                    .animation(FlySpring.standard.delay(Double(i) * 0.06), value: appeared)
                }
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Document Row Card

struct DocumentRowCard: View {
    let document: FlyDocument
    let onTap: () -> Void
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Thumbnail
                DocumentThumbnail(document: document)

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(document.name)
                        .font(FlyFont.body(15))
                        .foregroundStyle(FlyColor.label)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        TypeBadge(type: document.type)

                        Text("·")
                            .foregroundStyle(FlyColor.silver)
                            .font(FlyFont.caption(11))

                        Text("\(document.pages)p")
                            .font(FlyFont.caption(12))
                            .foregroundStyle(FlyColor.secondaryLabel)

                        Text("·")
                            .foregroundStyle(FlyColor.silver)
                            .font(FlyFont.caption(11))

                        Text(document.formattedSize)
                            .font(FlyFont.caption(12))
                            .foregroundStyle(FlyColor.secondaryLabel)
                    }

                    Text(document.formattedDate)
                        .font(FlyFont.caption(12))
                        .foregroundStyle(FlyColor.tertiaryLabel)
                }

                Spacer(minLength: 0)

                // Actions
                VStack(spacing: 0) {
                    if document.isStarred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(FlyColor.warning)
                            .padding(.bottom, 6)
                    }

                    Menu {
                        Button("Share", systemImage: "square.and.arrow.up") {}
                        Button("Compress", systemImage: "arrow.down.circle") {}
                        Button("AI Analyze", systemImage: "sparkles") {}
                        Button("Star", systemImage: "star") {
                            appState.toggleStar(document)
                        }
                        Divider()
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appState.deleteDocument(document)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(FlyColor.silver)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(FlySpacing.md)
            .background(FlyColor.background, in: RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: FlyRadius.lg, style: .continuous)
                    .strokeBorder(FlyColor.separator.opacity(0.5), lineWidth: 0.5)
            }
            .flyShadowCard()
        }
        .buttonStyle(.flyPress(scale: 0.98))
    }
}

// MARK: - Document Thumbnail

struct DocumentThumbnail: View {
    let document: FlyDocument

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(document.thumbnailColor.opacity(0.1))
            .frame(width: 50, height: 62)
            .overlay {
                VStack(spacing: 3) {
                    Image(systemName: document.type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(document.thumbnailColor)

                    Text(document.type.rawValue.uppercased())
                        .font(FlyFont.label(7))
                        .foregroundStyle(document.thumbnailColor.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 4)
                }
            }
    }
}

// MARK: - Type Badge

struct TypeBadge: View {
    let type: DocumentType

    var body: some View {
        Text(type.rawValue)
            .font(FlyFont.label(10))
            .foregroundStyle(type.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    @Binding var expanded: Bool

    private let actions: [(icon: String, label: String, color: Color)] = [
        ("camera.fill",     "Scan",      FlyColor.warning),
        ("folder.badge.plus", "Import",  FlyColor.electricBlue),
        ("sparkles",        "AI Create", FlyColor.violet),
    ]

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            if expanded {
                ForEach(actions.indices.reversed(), id: \.self) { i in
                    FABSecondaryButton(
                        icon: actions[i].icon,
                        label: actions[i].label,
                        color: actions[i].color
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(FlySpring.bouncy.delay(Double(actions.count - 1 - i) * 0.06), value: expanded)
                }
            }

            // Primary FAB
            Button {
                withAnimation(FlySpring.bouncy) {
                    expanded.toggle()
                    FlyHaptic.medium()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(FlyColor.brandGradient)
                        .frame(width: 62, height: 62)
                        .flyShadowBlue()
                        .shadow(color: FlyColor.electricBlue.opacity(0.4), radius: 24, y: 10)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(expanded ? 45 : 0))
                        .animation(FlySpring.bouncy, value: expanded)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct FABSecondaryButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Button {
            FlyHaptic.light()
        } label: {
            HStack(spacing: 10) {
                Text(label)
                    .font(FlyFont.caption())
                    .fontWeight(.medium)
                    .foregroundStyle(FlyColor.label)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .flyGlass(cornerRadius: FlyRadius.pill)
                    .flyShadowSoft()

                Circle()
                    .fill(color)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: color.opacity(0.4), radius: 10, y: 4)
            }
        }
        .buttonStyle(.flyPress)
    }
}

// MARK: - Processing Banner

struct ProcessingBanner: View {
    let task: ProcessingTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(FlyColor.electricBlue, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(FlyFont.caption())
                    .fontWeight(.medium)
                    .foregroundStyle(FlyColor.label)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(FlyColor.secondaryBg).frame(height: 4)
                        Capsule()
                            .fill(FlyColor.brandGradient)
                            .frame(width: geo.size.width * task.progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Text("\(Int(task.progress * 100))%")
                .font(FlyFont.caption(12))
                .fontWeight(.semibold)
                .foregroundStyle(FlyColor.electricBlue)
                .frame(width: 36)
        }
        .padding(.horizontal, FlySpacing.md)
        .padding(.vertical, FlySpacing.sm + 2)
        .flyGlass(cornerRadius: FlyRadius.md)
        .flyShadowSoft()
        .padding(.horizontal, FlySpacing.lg)
        .padding(.top, FlySpacing.sm)
    }
}

// MARK: - Empty State

struct EmptyDocumentsState: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FlyColor.electricBlue.opacity(0.06 - Double(i) * 0.015))
                        .frame(width: 90, height: 110)
                        .rotationEffect(.degrees(Double(i - 1) * 12))
                        .offset(y: animate ? Double(i) * -4 : 0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(i) * 0.2),
                            value: animate
                        )
                }

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(FlyColor.electricBlue)
                    .background(Circle().fill(FlyColor.background).padding(-4))
            }
            .frame(height: 120)

            VStack(spacing: 8) {
                Text("No documents yet")
                    .font(FlyFont.subheading())
                    .foregroundStyle(FlyColor.label)

                Text("Import a PDF, scan something,\nor let AI create one for you.")
                    .font(FlyFont.body())
                    .foregroundStyle(FlyColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            HStack(spacing: 12) {
                Button {
                    FlyHaptic.medium()
                } label: {
                    Label("Scan Document", systemImage: "viewfinder")
                        .font(FlyFont.body(15))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(FlyColor.brandGradient, in: Capsule())
                        .flyShadowBlue()
                }
                .buttonStyle(.flyPress)

                Button {
                    FlyHaptic.light()
                } label: {
                    Label("Import File", systemImage: "folder.fill")
                        .font(FlyFont.body(15))
                        .fontWeight(.medium)
                        .foregroundStyle(FlyColor.label)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .flyGlass(cornerRadius: FlyRadius.pill)
                }
                .buttonStyle(.flyPress)
            }
        }
        .padding(.horizontal, FlySpacing.xl)
        .onAppear { animate = true }
    }
}

// MARK: - Search View (stub)

struct SearchView: View {
    @State private var query = ""

    var body: some View {
        VStack(spacing: FlySpacing.md) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FlyColor.silver)
                TextField("Search or ask AI…", text: $query)
                    .font(FlyFont.body())
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(FlyColor.silver)
                    }
                }
            }
            .padding(FlySpacing.md)
            .flyGlass(cornerRadius: FlyRadius.md)
            .padding(.horizontal, FlySpacing.lg)
            .padding(.top, FlySpacing.lg)

            Spacer()

            Text("Type to search documents or ask AI anything")
                .font(FlyFont.body())
                .foregroundStyle(FlyColor.secondaryLabel)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}
