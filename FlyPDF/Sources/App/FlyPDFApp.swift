import SwiftUI

// MARK: - App Entry Point

@main
struct FlyPDFApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootView()
                        .environmentObject(appState)
                        .transition(.opacity)
                } else {
                    OnboardingFlow()
                        .environmentObject(appState)
                        .transition(.opacity)
                }
            }
            .animation(FlySpring.hero, value: hasCompletedOnboarding)
            .preferredColorScheme(appState.colorScheme)
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var documents: [FlyDocument] = FlyDocument.samples
    @Published var selectedDocument: FlyDocument?
    @Published var isPremium: Bool = false
    @Published var colorScheme: ColorScheme? = nil
    @Published var showingAIChat: Bool = false
    @Published var processingTask: ProcessingTask?

    func addDocument(_ doc: FlyDocument) {
        documents.insert(doc, at: 0)
    }

    func deleteDocument(_ doc: FlyDocument) {
        documents.removeAll { $0.id == doc.id }
    }

    func toggleStar(_ doc: FlyDocument) {
        if let idx = documents.firstIndex(of: doc) {
            documents[idx].isStarred.toggle()
            FlyHaptic.selection()
        }
    }
}

struct ProcessingTask: Identifiable {
    let id = UUID()
    let title: String
    var progress: Double
    let icon: String
}

// MARK: - Root View (Tab + Navigation)

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab = .home
    @Namespace private var heroNamespace

    enum Tab: String, CaseIterable {
        case home    = "Home"
        case tools   = "Tools"
        case vault   = "Vault"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home:    return "square.grid.2x2.fill"
            case .tools:   return "wrench.and.screwdriver.fill"
            case .vault:   return "lock.shield.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(namespace: heroNamespace)
                    .tag(Tab.home)

                ToolsView()
                    .tag(Tab.tools)

                VaultView()
                    .tag(Tab.vault)

                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            FlyTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar

struct FlyTabBar: View {
    @Binding var selectedTab: RootView.Tab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(FlySpring.snappy) {
                        selectedTab = tab
                        FlyHaptic.selection()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(
                                selectedTab == tab
                                    ? FlyColor.electricBlue
                                    : FlyColor.silver
                            )
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                            .animation(FlySpring.snappy, value: selectedTab)

                        Text(tab.rawValue)
                            .font(FlyFont.label(10))
                            .foregroundStyle(
                                selectedTab == tab
                                    ? FlyColor.electricBlue
                                    : FlyColor.silver
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, FlySpacing.sm)
        .flyGlass(cornerRadius: FlyRadius.xl)
        .flyShadowSoft()
        .padding(.horizontal, FlySpacing.lg)
        .padding(.bottom, FlySpacing.lg)
    }
}
