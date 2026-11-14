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
    @Environment(\.managedObjectContext) private var viewContext

    private var appVersion: String {
        AppConstants.Strings.appVersion.isEmpty ? "1.0" : AppConstants.Strings.appVersion
    }

    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    @AppStorage(AppConstants.Strings.storage) private var hasCompletedOnboarding = false
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
                Text(AppConstants.Strings.welcome)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)

                CollectionStatsView()

                VStack(spacing: 16) {
                    Button {
                        showScanner = true
                    } label: {
                        Label(AppConstants.Strings.scanNow, systemImage: AppConstants.Icons.cameraViewfinder)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .accessibilityLabel(AppConstants.Accessibility.startScanningABook)
                    .accessibilityHint(AppConstants.Accessibility.startScanningHint)

                    Button {
                        showSubjectBrowse = true
                    } label: {
                        Label(AppConstants.Strings.browseBooks, systemImage: AppConstants.Icons.tag)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .accessibilityLabel(AppConstants.Accessibility.browseBooks)
                    .accessibilityHint(AppConstants.Accessibility.browseBooksHint)

                    Button {
                        isLoadingLibrary = true
                        showLibrary = true
                    } label: {
                        Label(AppConstants.Strings.viewSavedBooks(count: savedBooks.count), systemImage: AppConstants.Icons.booksVertical)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .accessibilityLabel(AppConstants.Accessibility.viewSavedBooks)
                    .accessibilityValue(
                        AppConstants
                            .Accessibility
                            .savedBooks(savedBooks.count)
                    )
                    .accessibilityHint(AppConstants.Accessibility.viewSavedBooksHint)
                }

                VStack(spacing: 4) {
                    Text("\(AppConstants.Strings.version) \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
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
                        Text(AppConstants.Strings.loadingBooks)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
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
            SubjectBrowseView(viewContext: viewContext)
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
