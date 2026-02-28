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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
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
        ScrollView {
            VStack(spacing: 20) {
                Text("Welcome to Book Scanner")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                CollectionStatsView()

                VStack(spacing: 16) {
                    Button {
                        showScanner = true
                    } label: {
                        Label("Scan Now", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Start scanning a book")
                    .accessibilityHint("Opens the camera to scan a barcode or QR code")

                    Button {
                        showSubjectBrowse = true
                    } label: {
                        Label("Browse Books", systemImage: "tag")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("Browse Books")
                    .accessibilityHint("Opens subject browse using Open Library API")

                    Button {
                        isLoadingLibrary = true
                        showLibrary = true
                    } label: {
                        Label("View Saved Books (\(savedBooks.count))", systemImage: "books.vertical")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .accessibilityLabel("View saved books")
                    .accessibilityValue("\(savedBooks.count) books")
                    .accessibilityHint("Opens your saved library")
                }
            }
            .padding(20)
        }
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
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
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
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )) {
            OnboardingCarouselView {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
