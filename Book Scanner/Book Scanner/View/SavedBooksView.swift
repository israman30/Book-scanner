//
//  SavedBooksView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/21/26.
//

import SwiftUI
import CoreData

struct SavedBooksView: View {
    var onBooksLoaded: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.title, ascending: true)],
        animation: .default
    )
    private var savedBooks: FetchedResults<BookEntity>

    var body: some View {
        NavigationStack {
            Group {
                if savedBooks.isEmpty {
                    emptyLibraryView
                } else {
                    List {
                        ForEach(savedBooks, id: \.objectID) { book in
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
                                viewContext.delete(savedBooks[index])
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
            .onAppear { onBooksLoaded?() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close library")
                }
                ToolbarItem(placement: .primaryAction) {
                    if !savedBooks.isEmpty {
                        EditButton()
                        .accessibilityLabel("Edit saved books")
                    }
                }
            }
        }
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

