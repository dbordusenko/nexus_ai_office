import SwiftUI
import Foundation

// MARK: - PDF Document Model

struct FlyDocument: Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: URL?
    var pages: Int
    var sizeBytes: Int
    var dateModified: Date
    var type: DocumentType
    var tags: [String]
    var isStarred: Bool
    var isInVault: Bool
    var aiSummary: String?
    var thumbnailColor: Color

    init(
        id: UUID = UUID(),
        name: String,
        url: URL? = nil,
        pages: Int,
        sizeBytes: Int,
        dateModified: Date = Date(),
        type: DocumentType = .other,
        tags: [String] = [],
        isStarred: Bool = false,
        isInVault: Bool = false,
        thumbnailColor: Color = FlyColor.electricBlue
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.pages = pages
        self.sizeBytes = sizeBytes
        self.dateModified = dateModified
        self.type = type
        self.tags = tags
        self.isStarred = isStarred
        self.isInVault = isInVault
        self.thumbnailColor = thumbnailColor
    }

    var formattedSize: String {
        let mb = Double(sizeBytes) / 1_000_000
        if mb < 1 { return "\(Int(mb * 1000)) KB" }
        return String(format: "%.1f MB", mb)
    }

    var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(dateModified) {
            let f = DateFormatter()
            f.dateFormat = "HH:mm"
            return "Today, \(f.string(from: dateModified))"
        }
        if cal.isDateInYesterday(dateModified) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: dateModified)
    }

    static func == (lhs: FlyDocument, rhs: FlyDocument) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Document Type

enum DocumentType: String, CaseIterable {
    case contract     = "Contract"
    case invoice      = "Invoice"
    case receipt      = "Receipt"
    case report       = "Report"
    case presentation = "Presentation"
    case resume       = "Resume"
    case form         = "Form"
    case id           = "ID"
    case other        = "Document"

    var icon: String {
        switch self {
        case .contract:     return "doc.badge.checkmark"
        case .invoice:      return "doc.text.fill"
        case .receipt:      return "creditcard.fill"
        case .report:       return "chart.bar.doc.horizontal.fill"
        case .presentation: return "rectangle.on.rectangle.fill"
        case .resume:       return "person.text.rectangle.fill"
        case .form:         return "list.clipboard.fill"
        case .id:           return "person.crop.rectangle.badge.checkmark.fill"
        case .other:        return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .contract:     return FlyColor.electricBlue
        case .invoice:      return FlyColor.success
        case .receipt:      return FlyColor.warning
        case .report:       return FlyColor.violet
        case .presentation: return FlyColor.ultraViolet
        case .resume:       return FlyColor.info
        case .form:         return Color(hex: "#FF6B6B")
        case .id:           return FlyColor.electricBlue
        case .other:        return FlyColor.silver
        }
    }
}

// MARK: - Quick Action

struct QuickAction: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let gradient: LinearGradient
    let isPremium: Bool

    static let all: [QuickAction] = [
        QuickAction(
            name: "Merge",
            icon: "arrow.triangle.merge",
            gradient: LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#0055D4")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "Compress",
            icon: "arrow.down.circle.fill",
            gradient: LinearGradient(colors: [Color(hex: "#5E5CE6"), Color(hex: "#3A37B4")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "Convert",
            icon: "arrow.2.squarepath",
            gradient: LinearGradient(colors: [Color(hex: "#AF52DE"), Color(hex: "#7B2AB6")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "Sign",
            icon: "signature",
            gradient: LinearGradient(colors: [Color(hex: "#34C759"), Color(hex: "#1E8C3A")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "Scan",
            icon: "viewfinder",
            gradient: LinearGradient(colors: [Color(hex: "#FF9F0A"), Color(hex: "#CC7A00")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "AI Chat",
            icon: "sparkles",
            gradient: LinearGradient(colors: [Color(hex: "#007AFF"), Color(hex: "#AF52DE")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: false
        ),
        QuickAction(
            name: "Translate",
            icon: "globe",
            gradient: LinearGradient(colors: [Color(hex: "#32ADE6"), Color(hex: "#0076A3")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: true
        ),
        QuickAction(
            name: "OCR",
            icon: "doc.text.viewfinder",
            gradient: LinearGradient(colors: [Color(hex: "#FF6B6B"), Color(hex: "#CC3333")], startPoint: .topLeading, endPoint: .bottomTrailing),
            isPremium: true
        ),
    ]
}

// MARK: - AI Suggestion

struct AISuggestion: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let accentColor: Color
    let actionLabel: String
    let documentId: UUID?

    static let samples: [AISuggestion] = [
        AISuggestion(icon: "sparkles", text: "Contract ready to review", accentColor: FlyColor.electricBlue, actionLabel: "Analyze", documentId: nil),
        AISuggestion(icon: "arrow.down.circle.fill", text: "Resume needs compression", accentColor: FlyColor.violet, actionLabel: "Compress", documentId: nil),
        AISuggestion(icon: "globe", text: "Invoice detected in Russian", accentColor: FlyColor.success, actionLabel: "Translate", documentId: nil),
        AISuggestion(icon: "signature", text: "Document needs a signature", accentColor: FlyColor.warning, actionLabel: "Sign", documentId: nil),
    ]
}

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role { case user, assistant }
    let role: Role
    let text: String
    let timestamp: Date
    var sourcePage: Int?

    init(role: Role, text: String, sourcePage: Int? = nil) {
        self.role = role
        self.text = text
        self.timestamp = Date()
        self.sourcePage = sourcePage
    }
}

// MARK: - Conversion Format

enum ConversionFormat: String, CaseIterable {
    case word   = "Word"
    case excel  = "Excel"
    case pptx   = "PowerPoint"
    case images = "Images"
    case txt    = "TXT"
    case epub   = "EPUB"

    var icon: String {
        switch self {
        case .word:   return "doc.text.fill"
        case .excel:  return "tablecells.fill"
        case .pptx:   return "rectangle.on.rectangle.fill"
        case .images: return "photo.stack.fill"
        case .txt:    return "text.alignleft"
        case .epub:   return "books.vertical.fill"
        }
    }

    var color: Color {
        switch self {
        case .word:   return Color(hex: "#2B7CD3")
        case .excel:  return Color(hex: "#217346")
        case .pptx:   return Color(hex: "#D24726")
        case .images: return FlyColor.violet
        case .txt:    return FlyColor.silver
        case .epub:   return FlyColor.warning
        }
    }

    var fileExtension: String {
        switch self {
        case .word:   return ".docx"
        case .excel:  return ".xlsx"
        case .pptx:   return ".pptx"
        case .images: return ".jpg"
        case .txt:    return ".txt"
        case .epub:   return ".epub"
        }
    }
}

// MARK: - Sample Data

extension FlyDocument {
    static let samples: [FlyDocument] = [
        FlyDocument(
            name: "Q4 Financial Report.pdf",
            pages: 24,
            sizeBytes: 2_400_000,
            dateModified: Date().addingTimeInterval(-3600),
            type: .report,
            thumbnailColor: FlyColor.violet
        ),
        FlyDocument(
            name: "Service Agreement 2026.pdf",
            pages: 8,
            sizeBytes: 890_000,
            dateModified: Date().addingTimeInterval(-86400),
            type: .contract,
            isStarred: true,
            thumbnailColor: FlyColor.electricBlue
        ),
        FlyDocument(
            name: "Invoice #1042 — Airbnb.pdf",
            pages: 2,
            sizeBytes: 145_000,
            dateModified: Date().addingTimeInterval(-259200),
            type: .invoice,
            thumbnailColor: FlyColor.success
        ),
        FlyDocument(
            name: "Product Roadmap 2026.pdf",
            pages: 16,
            sizeBytes: 5_100_000,
            dateModified: Date().addingTimeInterval(-432000),
            type: .presentation,
            thumbnailColor: FlyColor.ultraViolet
        ),
        FlyDocument(
            name: "CV — Senior Designer.pdf",
            pages: 2,
            sizeBytes: 320_000,
            dateModified: Date().addingTimeInterval(-604800),
            type: .resume,
            thumbnailColor: FlyColor.info
        ),
    ]
}
