# Book Scanner

An iOS app to build and manage a personal book catalog by scanning barcodes, browsing online, and saving book metadata to your library (synced via iCloud).

## Features

- **Barcode scanning** — Scan ISBN barcodes or QR codes for quick book lookup
- **Browse books** — Search by ISBN, author, title, or subject via Open Library API
- **Saved library** — Store books with metadata, notes, favorites, and thumbnails
- **iCloud sync** — Library syncs across devices using Core Data + CloudKit
- **Share** — Export single books or your full list as text files

## Tech Stack

- SwiftUI · Core Data · CloudKit · AVFoundation · Open Library API

## Documentation

- **[Architecture & Design](docs/ARCHITECTURE.md)** — Design patterns, data flow, components, and technology choices

## Requirements

- iOS 17+
- Xcode 15+
- Camera access (for scanning)

## License

See project license file.
