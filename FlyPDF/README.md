# ✈️ FlyPDF — iOS App

> **"PDF without friction."**  
> The fastest AI PDF editor for iPhone and iPad.

---

## Project Structure

```
FlyPDF/
├── PRODUCT_VISION.md          ← Full 20-point product document
├── README.md                  ← This file
└── Sources/
    ├── App/
    │   └── FlyPDFApp.swift    ← App entry, AppState, RootView, custom TabBar
    ├── Design/
    │   ├── DesignTokens.swift ← Colors, typography, spacing, glass, haptics, button styles
    │   └── MotionSystem.swift ← Transitions, shimmer, pulse, hero, particle system
    ├── Models/
    │   └── PDFDocument.swift  ← FlyDocument, QuickAction, AISuggestion, ChatMessage, ConversionFormat
    └── Views/
        ├── Onboarding/
        │   └── OnboardingFlow.swift     ← 4-screen animated onboarding
        ├── Home/
        │   └── HomeView.swift           ← Main screen: header, AI strip, quick actions, recent docs, FAB
        ├── Document/
        │   └── DocumentViewer.swift     ← Full-screen PDFKit viewer, chrome, tools sheet, AI orb
        ├── AI/
        │   └── AIAssistantView.swift    ← Floating orb + streaming chat + suggestions
        ├── Tools/
        │   └── ConversionView.swift     ← Format picker, processing animation, done/error states
        └── Premium/
            ├── PremiumPaywall.swift     ← Full-screen paywall with animated gradient
            ├── ToolsVaultProfile.swift  ← All Tools grid, Vault (Face ID), Profile/Settings
            └── (ScannerView in Components)
    ├── Components/
        ├── ScannerView.swift            ← VisionKit scanner + OCR processing + AI rename
        └── WidgetsExtension.swift       ← Small / Medium / Large / Lock Screen widgets
```

---

## Design System

| Token | Value |
|-------|-------|
| Electric Blue | `#007AFF` |
| Violet | `#5E5CE6` |
| Ultra Violet | `#AF52DE` |
| Corner Radius (default) | 24pt |
| Spring (standard) | response: 0.35, damping: 0.70 |
| Spring (snappy) | response: 0.25, damping: 0.75 |
| Spring (bouncy) | response: 0.45, damping: 0.60 |

---

## Key Features Implemented

### Screens
- **Onboarding** — 4 animated slides, gradient background transitions, flying papers + AI orb + conversion + vault illustrations
- **Home** — greeting, AI suggestion strip, 8 quick-action buttons (with premium crown), recent documents list
- **Document Viewer** — full-screen PDFKit, auto-hide chrome, AI orb, tools bottom sheet
- **AI Chat** — streaming response simulation, source citations, suggestion chips, voice input stub
- **Conversion** — format picker grid, orbital processing animation, success confetti, error handling
- **Scanner** — VisionKit integration, animated scan frame with laser line, OCR processing, AI auto-rename
- **Premium Paywall** — animated dark gradient, feature list, 3-tier plan picker
- **Tools** — grouped tool cards (AI / Edit / Convert / Security)
- **Vault** — Face ID lock/unlock with animation
- **Profile / Settings** — upgrade banner, settings sections

### Design System
- Glassmorphism (`flyGlass()`) with border + material
- Soft + blue + violet + card shadows
- `FlyPressButtonStyle` with haptic
- Complete `FlyColor`, `FlyFont`, `FlySpacing`, `FlyRadius` tokens
- `FlySpring` presets (snappy / standard / bouncy / slow / hero)
- `FlyHaptic` static utility

### Motion System
- Staggered list entry animations
- Shimmer skeleton loading
- Particle burst system
- Hero matched geometry transitions
- Scroll reveal modifier
- Pulse glow effect
- SuccessBurst celebration view

### Widgets (WidgetKit)
- Small (2×2): Recent document
- Medium (4×2): Quick actions + recent
- Large (4×4): Dashboard with storage bar
- Lock screen: Doc count

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| UI | SwiftUI 5.0 (iOS 17+) |
| PDF | PDFKit (Apple native) |
| Scanning | VisionKit |
| On-device AI | CoreML + Vision |
| Cloud AI | Anthropic Claude API |
| Payments | RevenueCat + StoreKit 2 |
| Sync | CloudKit |
| Widgets | WidgetKit |
| Analytics | Mixpanel |
| Crash | Sentry |

---

## Getting Started

1. Open `FlyPDF.xcodeproj` in Xcode 15+
2. Set your development team in Signing & Capabilities
3. Add `ANTHROPIC_API_KEY` to your `.xcconfig` or environment
4. Run on iPhone 14 Pro or later (for ProMotion 120fps)

---

## Monetization

| Tier | Price | Key Features |
|------|-------|--------------|
| Free | $0 | View, basic compress (1/day), scan (3/day), AI (5/day) |
| Pro | $4.99/mo · $34.99/yr | Unlimited all features, OCR, signatures, iCloud sync |
| Ultra | $9.99/mo · $69.99/yr | AI contract analysis, batch, team workspace, vault |
| Lifetime | $149.99 | Everything, forever |

---

*FlyPDF — Built for the era where every document is intelligent.*
