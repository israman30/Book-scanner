//
//  SavedBooksView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/21/26.
//

import SwiftUI
import CoreData
import UIKit

struct SavedBooksView: View {
    var onBooksLoaded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.title, ascending: true)],
        animation: .default
    )
    private var savedBooks: FetchedResults<BookEntity>

    /// Books filtered by search across title, author, ISBN, and subjects.
    private var filteredBooks: [BookEntity] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty { return Array(savedBooks) }
        return savedBooks.filter { book in
            let title = (book.title ?? "").lowercased()
            let authors = (book.authors ?? "").lowercased()
            let isbn = (book.isbn ?? "").lowercased()
            let subjects = (book.subjects ?? "").lowercased()
            return title.contains(query) || authors.contains(query) || isbn.contains(query) || subjects.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if savedBooks.isEmpty {
                    emptyLibraryView
                } else if filteredBooks.isEmpty {
                    noSearchResultsView
                } else {
                    List {
                        ForEach(filteredBooks, id: \.objectID) { book in
                            NavigationLink {
                                EditableBookDetailView(book: book)
                            } label: {
                                SavedBookCardView(book: book)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                            )
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                viewContext.delete(filteredBooks[index])
                            }
                            PersistenceController.shared.save()
                        }
                    }
                    .listStyle(.automatic)
                    .scrollContentBackground(.hidden)
                    .listRowSpacing(12)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("My Books")
            .searchable(text: $searchText, prompt: "Search by title, author, ISBN, or subject")
            .onAppear { onBooksLoaded?() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close library")
                }
                ToolbarItem(placement: .primaryAction) {
                    if !filteredBooks.isEmpty {
                        EditButton()
                            .accessibilityLabel("Edit saved books")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    if !filteredBooks.isEmpty {
                        ShareBookListButton(books: filteredBooks.map(\.toSavedBook))
                            .accessibilityLabel("Share book list")
                            .accessibilityHint("Share your book list with friends or family")
                    }
                }
            }
        }
    }
    
    /// Share button that exports the book list and presents the system share sheet.
    private struct ShareBookListButton: View {
        let books: [SavedBook]
        @State private var showShareSheet = false
        @State private var shareItems: [Any] = []

        var body: some View {
            Button {
                shareItems = [exportBookList()]
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }

        private func exportBookList() -> URL {
            let content = books.enumerated().map { index, book in
                let authors = book.authors.isEmpty ? "" : " by \(book.authors)"
                let isbn = book.isbn.map { " (ISBN: \($0))" } ?? ""
                return "\(index + 1). \(book.title)\(authors)\(isbn)"
            }.joined(separator: "\n\n")

            let header = "My Book List (\(books.count) books)\n\n"
            let fullContent = header + content

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("MyBookList-\(formattedDate).txt")
            try? fullContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        }

        private var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }
    }

    /// System share sheet wrapper.
    private struct ShareSheet: UIViewControllerRepresentable {
        let items: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: items, applicationActivities: nil)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }

    /// Empty Library placeholder
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No books yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text("Scan and add books to see them here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No books yet")
        .accessibilityHint("Scan and add books to see them here")
    }

    /// Shown when search yields no matches.
    private var noSearchResultsView: some View {
        ContentUnavailableView.search(text: searchText)
    }

}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let context = controller.viewContext
    for sample in [
        SavedBook(title: "The Pragmatic Programmer", authors: "Andrew Hunt, David Thomas", isbn: "978-0201616224", publisher: "Addison-Wesley Professional", publishedDate: "1999", description: "One of the most significant books in my life.", subjects: "Programming, Software Development, Best Practices"),
        SavedBook(title: "Clean Code", authors: "Robert C. Martin", isbn: "978-0132350884", subjects: "Programming, Refactoring"),
        SavedBook(title: "SwiftUI Essentials", authors: "Apple Developer Documentation", isbn: nil, subjects: "Swift, iOS, Mobile Development")
    ] {
        _ = BookEntity.create(from: sample, in: context)
    }
    try? context.save()

    return SavedBooksView()
        .environment(\.managedObjectContext, context)
}

