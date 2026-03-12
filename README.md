# Book Scanner

**Version 1.0** · An iOS app to build and manage a personal book catalog by scanning barcodes, browsing online, and saving book metadata to your library (synced via iCloud).

---

## Functionality & Features

### Core Features
- **Barcode scanning** — Scan ISBN barcodes or QR codes for quick book lookup via camera
- **Browse books** — Search by ISBN, author, title, or subject using the Open Library API; optional "published in" date range for subject searches
- **Saved library** — Store books with metadata, notes, favorites, and thumbnails
- **iCloud sync** — Library syncs across devices using Core Data + CloudKit
- **Share & export** — Export single books or your full list as text files

### Error Handling
- **Persistence errors** — Structured parsing of Core Data and CloudKit errors via `PersistenceErrorHandler`; user-facing messages and debug logging

### Library Management
- **Collection stats** — Dashboard with total books, top subject, per-subject counts, and recently added
- **List & grid views** — Toggle between list and grid layouts
- **Search** — Filter saved books by title, author, ISBN, or subjects
- **Swipe actions** — Favorite, delete, or share directly from the list
- **Editable details** — Edit title, authors, notes, and more
- **Duplicate detection** — Prevents adding the same ISBN twice

### Onboarding
- **First-run carousel** — 4-page guided introduction: Welcome, Scan Book Barcodes, Browse by Subject, Save & Organize

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
│ BookService   │   │ PersistenceCont │   │ ViewModels / State    │
│ (Open Library)│   │ (Core Data +    │   │ SubjectBrowseViewModel│
└───────────────┘   │  iCloud sync)  │   │ @Environment / State  │
                    └────────────────┘   └──────────────────────┘
```

- **View layer** — SwiftUI views and UI components
- **Service layer** — `BookService` for Open Library API calls (async/await)
- **Persistence layer** — Core Data via `PersistenceController`; `PersistenceErrorHandler` for structured error handling
- **Model layer** — `BookItem` (API), `SavedBook` (display), `BookEntity` (Core Data)
- **ViewModel layer** — `SubjectBrowseViewModel` for browse/search logic; other views use `@State`, `@FetchRequest`, and `@Environment`

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
| Networking | URLSession (async/await) |
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

## Usage

### First Launch

On first launch, a 4-page onboarding carousel introduces the app:

1. **Welcome** — Overview of scanning, browsing, and saving books
2. **Scan Book Barcodes** — How to use the camera to scan ISBNs
3. **Browse by Subject** — How to search the Open Library catalog
4. **Save & Organize** — How to manage your library

Tap **Get Started** or **Skip** to reach the main screen.

### Home Screen

The home screen shows:

- **Your Collection** — Stats dashboard (when you have books): total count, top subject, books per subject, and recently added
- **Scan Now** — Opens the full-screen camera scanner
- **Browse Books** — Opens the search/browse interface
- **View Saved Books (N)** — Opens your library (N = number of saved books)

### Scanning Books

1. Tap **Scan Now**
2. Allow camera access when prompted
3. Align the book’s barcode or QR code inside the green frame
4. The app looks up the book via Open Library
5. When found, tap **Add to My Books** to save it
6. Tap the **×** button to close the scanner

Duplicate ISBNs are blocked; you’ll see a message if the book is already in your library.

### Browsing Books

1. Tap **Browse Books**
2. Choose a search type: **ISBN**, **Author**, **Title**, or **Subject**
3. Enter your query (e.g., author name, book title, subject like “fiction”)
4. For **Subject** searches, optionally add a date range (e.g., `1500-1600`)
5. Tap **Search**
6. Tap the **+** button on any result to add it to your library
7. Tap **Done** to close

### Managing Your Library

1. Tap **View Saved Books**
2. Use the search bar to filter by title, author, ISBN, or subject
3. Switch between **List** and **Grid** layouts with the toolbar button
4. Tap a book to open its detail view

**List view swipe actions:**

- Swipe right: **Favorite** / **Unfavorite**
- Swipe left: **Share**, **Delete**

**Grid view:** Long-press a book for **Share**, **Add/Remove from favorites**, or **Delete**

### Editing Book Details

1. Open a book from your library
2. Tap the **⋯** menu in the top-right
3. Choose **Edit** to change title, authors, notes, and other metadata
4. Save your changes

### Sharing & Exporting

- **Single book:** Swipe to **Share** in the list, or use the **⋯** menu → **Share** in the detail view
- **Full list:** Tap **Share** in the library toolbar to export all visible books as a text file

Exports are plain text files with title, authors, ISBN, publisher, dates, subjects, and notes.

---

## Contribution Requirements and Policies

Contributions are welcome. Please follow these guidelines:

1. **Pull requests** — Open a PR against `main` with a clear description of changes
2. **Code style** — Match existing Swift/SwiftUI conventions and formatting
3. **Testing** — Ensure `Book_ScannerTests` pass (including `SubjectBrowseViewModelTests`); add tests for new behavior when appropriate
4. **Scope** — Keep changes focused; split large features into smaller PRs
5. **Documentation** — Update `docs/ARCHITECTURE.md` for architectural changes

---

## Copyright

© 2025 Israel Manzo. All rights reserved.

See the project license file for terms of use.

---

## Version

**1.0** (Build 1)
