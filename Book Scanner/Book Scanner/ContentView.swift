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
    @State private var showSubjectBrowse = false
    @State private var isLoadingLibrary = false
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
                showSubjectBrowse = true
            } label: {
                Label("Browse Books", systemImage: "tag")
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
            .accessibilityLabel("Browse Books")
            .accessibilityHint("Opens subject browse using Open Library API")

            Button {
                isLoadingLibrary = true
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
        .overlay {
            if isLoadingLibrary {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading books...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            BookScannerView()
        }
        .sheet(isPresented: $showLibrary) {
            SavedBooksView(onBooksLoaded: { isLoadingLibrary = false })
        }
        .onChange(of: showLibrary) { _, isPresented in
            if !isPresented { isLoadingLibrary = false }
        }
        .sheet(isPresented: $showSubjectBrowse) {
            SubjectBrowseView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
