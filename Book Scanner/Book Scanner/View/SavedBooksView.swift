//
//  SavedBooksView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/21/26.
//

import SwiftUI
import CoreData
import UIKit

enum SavedBooksDisplayMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
}

struct SavedBooksView: View {
    var onBooksLoaded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var displayMode: SavedBooksDisplayMode = .list
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.title, ascending: true)],
        animation: .default
    )
    private var savedBooks: FetchedResults<BookEntity>

    /// Books filtered by search across title, author, ISBN, and subjects.
    private var filteredBooks: [BookEntity] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return Array(savedBooks)
        }
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
                } else if displayMode == .grid {
                    booksGridView
                } else {
                    booksListView
                }
            }
            .navigationTitle(AppConstants.Strings.myBooks)
            .searchable(text: $searchText, prompt: AppConstants.Strings.searchPlaceholderSubject)
            .onAppear {
                onBooksLoaded?()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppConstants.Strings.done) {
                        dismiss()
                    }
                    .accessibilityLabel(AppConstants.Accessibility.closeLibrary)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !filteredBooks.isEmpty && displayMode == .list {
                        EditButton()
                            .accessibilityLabel(AppConstants.Accessibility.editSavedBooks)
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    if !filteredBooks.isEmpty {
                        ShareBookListButton(books: filteredBooks.map(\.toSavedBook))
                            .accessibilityLabel(AppConstants.Accessibility.shareBookList)
                            .accessibilityHint(AppConstants.Accessibility.shareBookListHint)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !filteredBooks.isEmpty {
                        Button {
                            displayMode = displayMode == .list ? .grid : .list
                        } label: {
                            Image(systemName: displayMode == .list ? AppConstants.Icons.squareGrid2x2 : AppConstants.Icons.listBullet)
                            Text(displayMode == .list ? AppConstants.Strings.grid : AppConstants.Strings.list)
                        }
                        .accessibilityLabel(displayMode == .list ? AppConstants.Accessibility.switchToGridView : AppConstants.Accessibility.switchToListView)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    /// List layout with cards.
    private var booksListView: some View {
        List {
            ForEach(filteredBooks, id: \.objectID) { book in
                NavigationLink {
                    EditableBookDetailView(book: book)
                } label: {
                    SavedBookCardView(book: book)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                )
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        book.isFavorite.toggle()
                        PersistenceController.shared.save()
                    } label: {
                        Label(
                            book.isFavorite ? AppConstants.Strings.unfavorite : AppConstants.Strings.favorite,
                            systemImage: book.isFavorite ? AppConstants.Icons.heartSlash : AppConstants.Icons.heart
                        )
                    }
                    .tint(book.isFavorite ? .gray : .pink)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewContext.delete(book)
                        PersistenceController.shared.save()
                    } label: {
                        Label(AppConstants.Strings.delete, systemImage: AppConstants.Icons.trash)
                    }
                    Button {
                        shareItems = [exportSingleBook(book)]
                        showShareSheet = true
                    } label: {
                        Label(AppConstants.Strings.share, systemImage: AppConstants.Icons.share)
                    }
                    .tint(.blue)
                }
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
        .listRowSpacing(14)
        .background(Color(.systemGroupedBackground))
    }

    /// Grid layout with book covers.
    private var booksGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 16),
                GridItem(.adaptive(minimum: 100), spacing: 16),
                GridItem(.adaptive(minimum: 100), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredBooks, id: \.objectID) { book in
                    NavigationLink {
                        EditableBookDetailView(book: book)
                    } label: {
                        SavedBookGridCellView(book: book)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            shareItems = [exportSingleBook(book)]
                            showShareSheet = true
                        } label: {
                            Label(AppConstants.Strings.share, systemImage: AppConstants.Icons.share)
                        }
                        Button {
                            book.isFavorite.toggle()
                            PersistenceController.shared.save()
                        } label: {
                            Label(
                                book.isFavorite ? AppConstants.Strings.unfavorite : AppConstants.Strings.favorite,
                                systemImage: book.isFavorite ? AppConstants.Icons.heartSlash : AppConstants.Icons.heart
                            )
                        }
                        Divider()
                        Button(role: .destructive) {
                            viewContext.delete(book)
                            PersistenceController.shared.save()
                        } label: {
                            Label(AppConstants.Strings.delete, systemImage: AppConstants.Icons.trash)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func exportSingleBook(_ book: BookEntity) -> URL {
        let saved = book.toSavedBook
        var lines: [String] = [
            saved.title,
            saved.authors.isEmpty ? "" : "by \(saved.authors)",
            ""
        ]
        if let isbn = saved.isbn {
            lines.append("ISBN: \(isbn)")
        }
        if let publisher = saved.publisher {
            lines.append("Publisher: \(publisher)")
        }
        if let publishedDate = saved.publishedDate {
            lines.append("Published: \(publishedDate)")
        }
        if let subjects = saved.subjects, !subjects.isEmpty {
            lines.append("Subjects: \(subjects)")
        }
        if let description = saved.description, !description.isEmpty {
            lines.append("")
            lines.append(description)
        }
        if let notes = saved.notes, !notes.isEmpty {
            lines.append("")
            lines.append("Notes:")
            lines.append(notes)
        }
        let content = lines.joined(separator: "\n")
        let sanitizedTitle = saved.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: Date())
        let fileName = "\(sanitizedTitle)-\(dateStr).txt"
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
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
                Image(systemName: AppConstants.Icons.squareAndArrowUp)
                Text(AppConstants.Strings.share)
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

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
    }

    /// Empty Library placeholder
    private var emptyLibraryView: some View {
        VStack(spacing: 16) {
            Image(systemName: AppConstants.Icons.booksVertical)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text(AppConstants.Strings.noBooksYet)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(AppConstants.Strings.scanAndAddBooksToSeeThemHere)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AppConstants.Accessibility.noBooksYet)
        .accessibilityHint(AppConstants.Strings.scanAndAddBooksToSeeThemHere)
    }

    /// Shown when search yields no matches, with suggestion tips.
    private var noSearchResultsView: some View {
//        ContentUnavailableView(
//            "No results found",
//            description: "No books match \"\(searchText)\". Try a different or shorter search term, check your spelling, or search by author, title, ISBN, or subject.",
//            systemImage: "magnifyingglass"
//        )
        ContentUnavailableView("No results found", systemImage: "magnifyingglass", description: Text("No books match \"\(searchText)\". Try a different or shorter search term, check your spelling, or search by author, title, ISBN, or subject."))
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

