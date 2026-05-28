import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct FlyPDFWidgetEntry: TimelineEntry {
    let date: Date
    let recentDocuments: [FlyDocument]
    let storageUsedGB: Double
    let totalStorageGB: Double
    let aiCreditsRemaining: Int
}

// MARK: - Small Widget (2×2): Recent Document

struct SmallWidgetView: View {
    let entry: FlyPDFWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let doc = entry.recentDocuments.first {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("Recent")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: doc.type.icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white)

                    Text(doc.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(doc.formattedDate)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(14)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white)
                    Text("Import PDF")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Medium Widget (4×2): Quick Actions

struct MediumWidgetView: View {
    let entry: FlyPDFWidgetEntry

    private let actions: [(icon: String, label: String)] = [
        ("viewfinder",             "Scan"),
        ("arrow.2.squarepath",     "Convert"),
        ("sparkles",               "AI Chat"),
        ("signature",              "Sign"),
    ]

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))

            HStack(spacing: 0) {
                // Left: Recent
                VStack(alignment: .leading, spacing: 4) {
                    Text("FlyPDF")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color(hex: "#007AFF"))

                    Spacer()

                    if let doc = entry.recentDocuments.first {
                        VStack(alignment: .leading, spacing: 3) {
                            Image(systemName: doc.type.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(doc.thumbnailColor)

                            Text(doc.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text(doc.formattedDate)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity)

                Divider().opacity(0.3)

                // Right: Quick Actions
                VStack(spacing: 8) {
                    ForEach(actions.prefix(4), id: \.label) { action in
                        Link(destination: URL(string: "flypdf://\(action.label.lowercased())")!) {
                            HStack(spacing: 8) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#007AFF"))
                                    .frame(width: 20)
                                Text(action.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Large Widget (4×4): Dashboard

struct LargeWidgetView: View {
    let entry: FlyPDFWidgetEntry

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#007AFF"))
                        Text("FlyPDF")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text("\(entry.aiCreditsRemaining) AI credits")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#5E5CE6"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#5E5CE6").opacity(0.12), in: Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider().opacity(0.3)

                // Documents
                VStack(spacing: 0) {
                    ForEach(entry.recentDocuments.prefix(3)) { doc in
                        HStack(spacing: 10) {
                            Image(systemName: doc.type.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(doc.thumbnailColor)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(doc.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(doc.formattedDate)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        if doc.id != entry.recentDocuments.prefix(3).last?.id {
                            Divider().padding(.leading, 54).opacity(0.3)
                        }
                    }
                }

                Divider().opacity(0.3).padding(.top, 4)

                // Storage bar
                HStack(spacing: 10) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.2)).frame(height: 4)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#007AFF"), Color(hex: "#5E5CE6")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * storageRatio, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text(String(format: "%.1f/%.0f GB", entry.storageUsedGB, entry.totalStorageGB))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var storageRatio: CGFloat {
        guard entry.totalStorageGB > 0 else { return 0 }
        return CGFloat(entry.storageUsedGB / entry.totalStorageGB)
    }
}

// MARK: - Lock Screen Widget

struct LockScreenWidgetView: View {
    let entry: FlyPDFWidgetEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("\(entry.recentDocuments.count) docs")
                .font(.system(size: 12, weight: .semibold))
        }
    }
}

// MARK: - Widget Preview Stubs
// (In Xcode, register these views inside a WidgetBundle)

struct FlyPDFWidget_Previews: PreviewProvider {
    static let entry = FlyPDFWidgetEntry(
        date: Date(),
        recentDocuments: FlyDocument.samples,
        storageUsedGB: 1.4,
        totalStorageGB: 5.0,
        aiCreditsRemaining: 73
    )

    static var previews: some View {
        Group {
            SmallWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")

            MediumWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")

            LargeWidgetView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large")
        }
    }
}
