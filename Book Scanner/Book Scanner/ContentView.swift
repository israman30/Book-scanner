//
//  ContentView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/19/26.
//

import SwiftUI
import CoreData

/// Entry screen that lets users start a scan or open their saved library.
/// Fetches saved books from Core Data and routes to scanner/library sheets.
struct ContentView: View {
    @State private var showScanner = false
    @State private var showLibrary = false
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.title, ascending: true)],
        animation: .default
    )
    private var savedBooks: FetchedResults<BookEntity>

    var body: some View {
        VStack {
            Text("Welcome to Book Scanner")
                .font(.title2)
                .padding(.bottom, 16)
                .accessibilityAddTraits(.isHeader)

            Button {
                showScanner = true
            } label: {
                Label("Scan Now", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .accessibilityLabel("Start scanning a book")
            .accessibilityHint("Opens the camera to scan a barcode or QR code")

            Button {
                showLibrary = true
            } label: {
                Label("View Saved Books (\(savedBooks.count))", systemImage: "books.vertical")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .accessibilityLabel("View saved books")
            .accessibilityValue("\(savedBooks.count) books")
            .accessibilityHint("Opens your saved library")
        }
        .padding()
        .fullScreenCover(isPresented: $showScanner) {
            BookScannerView()
        }
        .sheet(isPresented: $showLibrary) {
            SavedBooksView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
