# Book Scanner

**Version 1.0** · An iOS app to build and manage a personal book catalog by scanning barcodes, browsing online, and saving book metadata to your library (synced via iCloud).

---

## Functionality & Features

### Core Features
- **Barcode scanning** — Scan ISBN barcodes or QR codes for quick book lookup via camera
- **Browse books** — Search by ISBN, author, title, or subject using the Open Library API
- **Subject browse** — Optional "published in" date range for subject searches
- **Saved library** — Store books with metadata, notes, favorites, and thumbnails
- **iCloud sync** — Library syncs across devices using Core Data + CloudKit
- **Share & export** — Export single books or your full list as text files

### Library Management
- **Collection stats** — Dashboard with total books, top subject, per-subject counts, and recently added
- **List & grid views** — Toggle between list and grid layouts
- **Search** — Filter saved books by title, author, ISBN, or subjects
- **Swipe actions** — Favorite, delete, or share directly from the list
- **Editable details** — Edit title, authors, notes, and more
- **Duplicate detection** — Prevents adding the same ISBN twice

### Onboarding
- **First-run carousel** — Guided introduction for new users (Scan, Browse, Save & Organize)

---

## Architecture

The app uses a **SwiftUI-centric architecture** with clear separation:

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                            │
│  ContentView · BookScannerView · SavedBooksView · SubjectBrowse  │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐   ┌────────────────┐   ┌──────────────────────┐
│ BookService   │   │ PersistenceCont │   │ @Environment / State  │
│ (Open Library)│   │ (Core Data +    │   │ (managedObjectContext,│
└───────────────┘   │  iCloud sync)  │   │  dismiss, etc.)       │
                    └────────────────┘   └──────────────────────┘
```

- **View layer** — SwiftUI views and UI components
- **Service layer** — `BookService` for Open Library API calls
- **Persistence layer** — Core Data via `PersistenceController`
- **Model layer** — `BookItem` (API), `SavedBook` (display), `BookEntity` (Core Data)

Views own state with `@State`, `@FetchRequest`, and `@Environment`. No explicit ViewModel layer.

See **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** for design patterns, data flow, and component details.

---

## Design

- **Declarative SwiftUI** — Reactive UI driven by state and environment
- **System design** — Uses `.accentColor`, `.secondarySystemGroupedBackground`, and semantic colors
- **Visual hierarchy** — Rounded corners (12–20pt), soft shadows, material overlays for loading
- **Subject badges** — Soft pastel palette for per-subject counts
- **UIKit integration** — `UIViewControllerRepresentable` for camera (AVFoundation) and share sheet

---

## Tech Stack

| Component   | Technology        |
|------------|-------------------|
| UI         | SwiftUI           |
| Camera     | AVFoundation      |
| Persistence| Core Data         |
| Sync       | CloudKit          |
| Networking | URLSession        |
| Data source| Open Library API  |

---

## Accessibility

- **VoiceOver** — `accessibilityLabel`, `accessibilityHint`, `accessibilityValue` on controls
- **Announcements** — `UIAccessibility.post(notification: .announcement, argument:)` for scan/lookup state changes
- **Haptics** — `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator` for scan success and actions
- **Semantic traits** — `accessibilityAddTraits(.isHeader)` for headings
- **Combined elements** — `accessibilityElement(children: .combine)` for grouped content
- **Decorative hiding** — `accessibilityHidden(true)` for non-essential visuals

---

## Requirements

- iOS 17+
- Xcode 15+
- Camera access (for scanning)
- iCloud account (optional, for sync)

---

## Contribution Requirements and Policies

Contributions are welcome. Please follow these guidelines:

1. **Pull requests** — Open a PR against `main` with a clear description of changes
2. **Code style** — Match existing Swift/SwiftUI conventions and formatting
3. **Testing** — Ensure `Book_ScannerTests` pass; add tests for new behavior when appropriate
4. **Scope** — Keep changes focused; split large features into smaller PRs
5. **Documentation** — Update `docs/ARCHITECTURE.md` for architectural changes

---

## Copyright

© 2025 Israel Manzo. All rights reserved.

See the project license file for terms of use.

---

## Version

**1.0** (Build 1)
