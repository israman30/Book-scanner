//
//  SavedBooksView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/21/26.
//

import SwiftUI

struct SavedBooksView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var savedBooks: [SavedBook]

    var body: some View {
        NavigationStack {
            Group {
                if savedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("No books yet")
                            .font(.headline)
                        Text("Scan and add books to see them here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach($savedBooks) { $book in
                            NavigationLink {
                                EditableBookDetailView(book: $book)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.headline)
                                    Text(book.authors)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    if let isbn = book.isbn {
                                        Text("ISBN: \(isbn)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            savedBooks.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !savedBooks.isEmpty {
                        EditButton()
                    }
                }
            }
        }
    }
}

struct EditableBookDetailView: View {
    @Binding var book: SavedBook

    var body: some View {
        Form {
            Section("Book Info") {
                TextField("Title", text: $book.title)
                TextField("Authors", text: $book.authors)

                if let isbn = book.isbn {
                    Text("ISBN: \(isbn)")
                } else {
                    Text("ISBN not available")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Edit Book")
    }
}

