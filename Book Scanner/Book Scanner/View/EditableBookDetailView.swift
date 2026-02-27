//
//  EditableBookDetailView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/26/26.
//

import SwiftUI
import CoreData

struct EditableBookDetailView: View {
    @ObservedObject var book: BookEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State var isPresented = false

    var body: some View {
        Form {
            Section("Cover") {
                HStack {
                    Spacer()
                    if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
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
                            isPresented = true
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
                TextField("Title", text: Binding(
                    get: { book.title ?? "" },
                    set: { book.title = $0 }
                ))
                TextField("Authors", text: Binding(
                    get: { book.authors ?? "" },
                    set: { book.authors = $0 }
                ))

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

                if let subjects = book.subjects, !subjects.isEmpty {
                    LabeledContent("Subjects", value: subjects)
                }
            }

            if let description = book.bookDescription, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .navigationTitle("Edit Book")
        .onDisappear {
            PersistenceController.shared.save()
        }
        .sheet(isPresented: $isPresented) {
            if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
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
    let controller = PersistenceController(inMemory: true)
    let context = controller.viewContext
    let sample = SavedBook(
        title: "The Pragmatic Programmer",
        authors: "Andrew Hunt, David Thomas",
        isbn: "978-0201616224",
        thumbnailURL: URL(string: "https://books.google.com/books/content?id=5wBQEp6ruIchC&printsec=frontcover&img=1&zoom=1"),
        publisher: "Addison-Wesley Professional",
        publishedDate: "1999",
        description: "One of the most significant books in my life. A practical guide to software development that emphasizes pragmatism, flexibility, and craft.",
        subjects: "Programming, Software Development, Best Practices"
    )
    let book = BookEntity.create(from: sample, in: context)
    try? context.save()

    return NavigationStack {
        EditableBookDetailView(book: book)
            .environment(\.managedObjectContext, context)
    }
}

