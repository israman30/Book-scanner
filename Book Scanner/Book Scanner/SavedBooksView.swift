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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No books yet")
                    .accessibilityHint("Scan and add books to see them here")
                } else {
                    List {
                        ForEach($savedBooks) { $book in
                            NavigationLink {
                                EditableBookDetailView(book: $book)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    if let url = book.thumbnailURL {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .progressViewStyle(.circular)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            case .failure:
                                                placeholder
                                            @unknown default:
                                                placeholder
                                            }
                                        }
                                        .frame(width: 60, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .accessibilityHidden(true)
                                    } else {
                                        placeholder
                                            .frame(width: 60, height: 90)
                                            .accessibilityHidden(true)
                                    }

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
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(book.title)
                                    .accessibilityValue(accessibilitySummary(for: book))
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

    private func accessibilitySummary(for book: SavedBook) -> String {
        var parts = ["Authors \(book.authors)"]
        if let isbn = book.isbn {
            parts.append("ISBN \(isbn)")
        }
        return parts.joined(separator: ". ")
    }

    /// Placeholder used when no thumbnail exists or fails to load.
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

struct EditableBookDetailView: View {
    @Binding var book: SavedBook
    @State var isPresented = false

    var body: some View {
        Form {
            Section("Cover") {
                HStack {
                    Spacer()
                    if let url = book.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(.circular)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholder
                            @unknown default:
                                placeholder
                            }
                        }
                        .frame(width: 120, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("Book cover")
                        .onTapGesture {
                            self.isPresented = true
                        }
                    } else {
                        placeholder
                            .frame(width: 120, height: 180)
                            .accessibilityLabel("No book cover available")
                    }
                    Spacer()
                }
            }

            Section("Book Info") {
                TextField("Title", text: $book.title)
                TextField("Authors", text: $book.authors)

                if let isbn = book.isbn {
                    LabeledContent("ISBN", value: isbn)
                } else {
                    LabeledContent("ISBN", value: "Not available")
                        .foregroundStyle(.secondary)
                }

                if let publisher = book.publisher {
                    LabeledContent("Publisher", value: publisher)
                } else {
                    LabeledContent("Publisher", value: "Not available")
                        .foregroundStyle(.secondary)
                }

                if let publishedDate = book.publishedDate {
                    LabeledContent("Published", value: publishedDate)
                } else {
                    LabeledContent("Published", value: "Not available")
                        .foregroundStyle(.secondary)
                }
            }

            if let description = book.description, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationTitle("Edit Book")
        .sheet(isPresented: $isPresented) {
            if let url = book.thumbnailURL {
                ThumbnailView(url: url)
            }
        }
    }

    /// Placeholder used when no thumbnail exists or fails to load.
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    SavedBooksPreviewContainer()
}

private struct SavedBooksPreviewContainer: View {
    @State private var books = [
        SavedBook(
            title: "The Pragmatic Programmer",
            authors: "Andrew Hunt, David Thomas",
            isbn: "978-0201616224",
            publisher: "Addison-Wesley Professional",
            publishedDate: "1999",
            description: "One of the most significant books in my life. It covers topics ranging from personal responsibility and career development to architectural techniques for keeping your code flexible and easy to adapt."
        ),
        SavedBook(
            title: "Clean Code",
            authors: "Robert C. Martin",
            isbn: "978-0132350884"
        ),
        SavedBook(
            title: "SwiftUI Essentials",
            authors: "Apple Developer Documentation",
            isbn: nil
        )
    ]

    var body: some View {
        SavedBooksView(savedBooks: $books)
    }
}

struct ThumbnailView: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .progressViewStyle(.circular)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}
