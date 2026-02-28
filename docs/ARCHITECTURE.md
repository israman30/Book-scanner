# Book Scanner — Design & Architecture Documentation

## Overview

**Book Scanner** is an iOS app that lets users build a personal book catalog by scanning barcodes, browsing online, and saving book metadata. It uses the [Open Library API](https://openlibrary.org/developers/api) for lookups and Core Data with iCloud for persistent storage.

---

## High-Level Architecture

The app follows a **SwiftUI-centric architecture** with clear separation between:

1. **View layer** — SwiftUI views and UI components
2. **Service layer** — `BookService` for external API calls
3. **Persistence layer** — Core Data via `PersistenceController`
4. **Model layer** — Data structures for API, display, and storage

There is no explicit ViewModel layer. Views own state with `@State`, `@FetchRequest`, and `@Environment`, and call services directly. This keeps the structure simple for the app’s scope.

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
│ (Open Library)│   │ (Core Data +    │   │ (managedObjectContext, │
└───────────────┘   │  iCloud sync)  │   │  dismiss, etc.)       │
                    └────────────────┘   └──────────────────────┘
```

---

## Project Structure

```
Book Scanner/
├── Book_ScannerApp.swift          # App entry point, injects Core Data context
├── ContentView.swift              # Main hub with Scan / Browse / Library actions
├── PersistenceController.swift    # Core Data stack + CloudKit configuration
├── BookService.swift              # Open Library API client
├── SavedBook.swift               # Value-type display model
├── BookEntity+CoreDataClass.swift # Core Data managed object
├── BookEntity+CoreDataProperties.swift  # Properties + SavedBook conversions
├── ThumbnailView.swift           # Full-screen cover viewer
└── View/
    ├── BookScannerView.swift     # Barcode scanner + lookup UI
    ├── SavedBooksView.swift     # Saved library (list/grid)
    ├── SavedBookCardView.swift  # List + grid cards
    ├── EditableBookDetailView.swift  # Detail + edit sheet
    ├── SubjectBrowseView.swift  # Browse by ISBN/author/title/subject
    └── CollectionStatsView.swift # Stats dashboard
```

---

## Design Patterns

### 1. **SwiftUI Declarative UI**

Views are built declaratively and react to state and environment values.

- `@State` for local UI state
- `@FetchRequest` for Core Data-backed lists
- `@Environment(\.managedObjectContext)` for persistence
- `@Environment(\.dismiss)` for sheet/navigation dismissal

### 2. **Service Layer**

`BookService` encapsulates all Open Library networking:

- Static methods: `search(isbn:)`, `search(query:)`, `searchByQuery`, `searchBySubject`
- Async work via completion handlers
- Maps API responses to app models (`BookItem`, `VolumeInfo`)

### 3. **Model Mapping**

Three main representations:

| Model       | Purpose                          | Location                                      |
|-------------|----------------------------------|-----------------------------------------------|
| `BookItem`  | API response (Open Library)      | `BookService.swift`                           |
| `SavedBook` | Display/sharing (value type)     | `SavedBook.swift`                             |
| `BookEntity`| Persistence (Core Data)          | `BookEntity+*.swift`                          |

Mappings:

- `BookItem` → `SavedBook`: `SavedBook(from: BookItem)`
- `SavedBook` → `BookEntity`: `BookEntity.create(from:in:)`
- `BookEntity` → `SavedBook`: `entity.toSavedBook`

### 4. **Environment-Based DI**

Core Data context is passed through the view hierarchy:

```swift
@main
struct Book_ScannerApp: App {
    let persistenceController = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
```

### 5. **UIViewControllerRepresentable**

UIKit integration for:

- `CameraScannerView` — barcode scanning via `AVFoundation`
- `ShareSheet` — `UIActivityViewController` for sharing

---

## Data Flow

### Scan → Save

1. `BookScannerView` opens full-screen camera.
2. `ScannerViewController` (UIKit) detects barcode via `AVCaptureMetadataOutput`.
3. `onCodeDetected` passes code to `BookService.search(isbn:)`.
4. Open Library returns `BookItem`.
5. `BookLookupSection` displays `BookDetailCard` and “Add to My Books”.
6. User taps add → `addBookToLibrary(_:)` converts `BookItem` → `SavedBook` → `BookEntity`, saves via Core Data, checks ISBN for duplicates.

### Browse → Save

1. `SubjectBrowseView` lets the user search by ISBN, author, title, or subject.
2. Calls `BookService.searchByQuery` or `searchBySubject`.
3. Results shown as `SubjectBookRow` with “Add” button.
4. Same `BookItem` → `SavedBook` → `BookEntity` pipeline as above.

### Library Display

1. `ContentView` uses `@FetchRequest` for `BookEntity`.
2. “View Saved Books” opens `SavedBooksView` as a sheet.
3. `SavedBooksView` uses its own `@FetchRequest`; updates propagate via Core Data.
4. List/grid modes; swipe actions for favorite/delete/share.
5. Navigation to `EditableBookDetailView` for editing and sharing.

---

## Core Components

### ContentView

- Central hub with three main actions: Scan, Browse, Library.
- Shows `CollectionStatsView` when the library has books.
- Presents sheets: `BookScannerView`, `SavedBooksView`, `SubjectBrowseView`.
- Uses overlay loading state when opening the library.

### BookScannerView

- Full-screen camera with `CameraScannerView`.
- Owns lookup state: `idle`, `loading`, `loaded`, `failed`.
- `BookLookupSection` and `BookDetailCard` show results.
- Handles permission and duplicate ISBN logic.

### SavedBooksView

- List or grid layout for saved books.
- Search across title, author, ISBN, subjects.
- Swipe: favorite, delete, share.
- Exports single books or full list to text files for sharing.

### EditableBookDetailView

- Full detail view: cover, metadata, notes.
- `BookEditSheet` for editing title, authors, notes.
- Share, edit, delete via toolbar and confirmation.

### SubjectBrowseView

- Search type picker: ISBN, author, title, subject.
- Subject search supports optional “published in” range.
- Renders results with `SubjectBookRow`; add triggers same save path as scanner.

### CollectionStatsView

- Total books, top subject, per-subject counts.
- Recently added list with thumbnails.

---

## Persistence & Sync

### PersistenceController

- `shared` for production, `preview` for in-memory preview.
- Uses `NSPersistentCloudKitContainer` for iCloud sync.
- Model defined in code (no external `.xcdatamodeld`).
- Options for automatic migration and mapping inference.

### BookEntity Schema

| Attribute         | Type   | Notes                  |
|-------------------|--------|------------------------|
| `id`              | UUID   | Primary identifier     |
| `title`           | String | Required               |
| `authors`         | String | Comma-separated        |
| `isbn`            | String | Optional               |
| `thumbnailURLString` | String | Cover URL          |
| `publisher`       | String |                        |
| `publishedDate`   | String |                        |
| `bookDescription` | String |                        |
| `subjects`        | String | Comma-separated        |
| `notes`           | String | User notes             |
| `isFavorite`      | Bool   | Default false          |
| `addedDate`       | Date   | When added             |

---

## External APIs

### Open Library

- **Search**: `https://openlibrary.org/search.json?q={query}`
  - Prefixes: `isbn:`, `author:`, `title:`, `subject:`
- **Subjects**: `https://openlibrary.org/subjects/{subject}.json?published_in={range}`
- **Covers**: `https://covers.openlibrary.org/b/id/{coverId}-M.jpg`

Errors are wrapped in `BookServiceError` and `BookResult` / `BookListResult`.

---

## Testing

`Book_ScannerTests` covers:

- **ScannerViewController**: callbacks, initial state, code detection, permission, reset.
- **SavedBook**: initialization, mapping from `BookItem`, HTTP→HTTPS URLs.
- **BookService**: error messages and result types.

Tests use in-memory Core Data (`PersistenceController.preview`) for previews.

---

## Accessibility

- `accessibilityLabel`, `accessibilityHint`, `accessibilityValue` on important controls.
- `UIAccessibility.post(notification: .announcement, argument:)` for VoiceOver on scan/lookup changes.
- Haptics: `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` for feedback.

---

## Technology Stack

| Component     | Technology                  |
|--------------|-----------------------------|
| UI           | SwiftUI                     |
| Camera       | AVFoundation                |
| Persistence  | Core Data                  |
| Sync         | CloudKit                   |
| Networking   | URLSession                 |
| Data source  | Open Library API           |

---

## Future Considerations

- **ViewModels**: If screens grow in logic, introduce `@Observable` or `ObservableObject` ViewModels.
- **Async/await**: Replace completion handlers with async APIs where possible.
- **Localization**: Add `Localizable.strings` for multi-language support.
- **Offline**: Cache API responses for offline browse and lookup.
