//
//  SubjectBrowseViewModel.swift
//  Book Scanner
//
//  View model for subject/browse search logic.
//

import Foundation
import SwiftUI
import CoreData
import UIKit
import Combine

enum SearchType: String, CaseIterable {
    case isbn = "ISBN"
    case author = "Author"
    case title = "Title"
    case subject = "Subject"
}

protocol SubjectBrowseViewModelProtocol {
    func performSearch()
    func addBookToLibrary(_ item: BookItem)
}

extension SubjectBrowseViewModel: SubjectBrowseViewModelProtocol { }

@MainActor
final class SubjectBrowseViewModel: ObservableObject {
    @Published var searchType: SearchType = .title
    @Published var searchInput = ""
    @Published var publishedIn = ""
    @Published var books: [BookItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var addMessage = ""
    @Published var showAddMessage = false
    @Published var justAddedTitle: String?

    private let viewContext: NSManagedObjectContext

    var searchPlaceholder: String {
        switch searchType {
        case .isbn: return "e.g. 978-0-385-50420-5"
        case .author: return "e.g. Jane Austen"
        case .title: return "e.g. Pride and Prejudice"
        case .subject: return "e.g. love, science, fiction"
        }
    }

    var isSearchDisabled: Bool {
        isLoading || searchInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    func performSearch() {
        // Treat whitespace-only input as empty to avoid firing requests that will
        // always return broad/irrelevant results (and to keep UI state stable).
        let trimmed = searchInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Reset UI state at the start of a search so results/messages always
        // correspond to the most recent request.
        isLoading = true
        errorMessage = nil
        books = []

        Task { @MainActor in
            // We keep networking isolated behind BookService and switch only on the
            // query grammar (isbn:/author:/title:/subject) here.
            let result: BookListResult
            switch searchType {
            case .isbn:
                let query = "isbn:\(trimmed)"
                result = await BookService.searchByQuery(query: query)
            case .author:
                let query = "author:\(trimmed)"
                result = await BookService.searchByQuery(query: query)
            case .title:
                let query = "title:\(trimmed)"
                result = await BookService.searchByQuery(query: query)
            case .subject:
                // Subjects are normalized to lower-case for consistent API matching.
                // The year range is optional; send `nil` when empty rather than an
                // empty string so the service can omit the parameter entirely.
                let subject = trimmed.lowercased()
                let range = publishedIn.trimmingCharacters(in: .whitespaces)
                let publishedParam = range.isEmpty ? nil : range
                result = await BookService.searchBySubject(subject: subject, publishedIn: publishedParam)
            }
            isLoading = false
            switch result {
            case .success(let items):
                books = items
                if items.isEmpty {
                    // "No results" is not an error from the network layer; it’s a
                    // user-facing empty state with a tailored message.
                    let term = searchType == .subject ? trimmed.lowercased() : trimmed
                    errorMessage = searchType == .subject
                        ? "No books found for subject \"\(term)\""
                        : "No books found for \(searchType.rawValue) \"\(term)\""
                }
            case .failure(let message):
                // Preserve the service-provided failure message for debugging and
                // to avoid losing potentially actionable context (e.g. bad URL).
                errorMessage = message
            }
        }
    }

    func addBookToLibrary(_ item: BookItem) {
        // Convert remote/API model into the local persistence representation.
        let newEntry = SavedBook(from: item)

        if let isbn = newEntry.isbn {
            // ISBN is the strongest identifier we have; use it to prevent duplicates
            // without scanning the entire store.
            let request = BookEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isbn == %@", isbn)
            request.fetchLimit = 1
            do {
                let existing = try viewContext.fetch(request)
                if !existing.isEmpty {
                    addMessage = "This book is already in your list."
                    showAddMessage = true
                    return
                }
            } catch {
                // If the duplicate check fails, we still attempt to save; the UX
                // should not be blocked by a best-effort preflight.
                print("Duplicate check failed: \(error)")
            }
        }

        _ = BookEntity.create(from: newEntry, in: viewContext)
        do {
            try viewContext.save()
            addMessage = "\"\(newEntry.title)\" added to your list."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                // Used by the list row to briefly highlight the item that was added.
                justAddedTitle = newEntry.title
            }
            Task { @MainActor in
                // Auto-clear the highlight after a short delay so it reads as a
                // transient “confirmation” rather than a persistent state.
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                justAddedTitle = nil
            }
        } catch {
            // Surface persistence failures explicitly—this is actionable for users.
            addMessage = "Could not save book: \(error.localizedDescription)"
        }
        showAddMessage = true
    }
}
