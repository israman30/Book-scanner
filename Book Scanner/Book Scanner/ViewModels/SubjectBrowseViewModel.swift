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
        let trimmed = searchInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        books = []

        Task { @MainActor in
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
                    let term = searchType == .subject ? trimmed.lowercased() : trimmed
                    errorMessage = searchType == .subject
                        ? "No books found for subject \"\(term)\""
                        : "No books found for \(searchType.rawValue) \"\(term)\""
                }
            case .failure(let message):
                errorMessage = message
            }
        }
    }

    func addBookToLibrary(_ item: BookItem) {
        let newEntry = SavedBook(from: item)

        if let isbn = newEntry.isbn {
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
                print("Duplicate check failed: \(error)")
            }
        }

        _ = BookEntity.create(from: newEntry, in: viewContext)
        do {
            try viewContext.save()
            addMessage = "\"\(newEntry.title)\" added to your list."
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                justAddedTitle = newEntry.title
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                justAddedTitle = nil
            }
        } catch {
            addMessage = "Could not save book: \(error.localizedDescription)"
        }
        showAddMessage = true
    }
}
