//
//  SubjectBrowseView.swift
//  Book Scanner
//
//  Browse books by subject using Open Library subjects API.
//  API: https://openlibrary.org/subjects/{subject}.json?published_in=1500-1600
//

import SwiftUI
import CoreData

struct SubjectBrowseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var subjectInput = "love"
    @State private var publishedIn = "1500-1600"
    @State private var books: [BookItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var addMessage = ""
    @State private var showAddMessage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("e.g. love, science, fiction", text: $subjectInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)

                    Text("Published in (optional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("e.g. 1500-1600 or leave empty", text: $publishedIn)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                }
                .padding(.horizontal)

                Button {
                    searchBySubject()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Search by Subject")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading || subjectInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(books.enumerated()), id: \.offset) { _, book in
                            SubjectBookRow(book: book) {
                                addBookToLibrary(book)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Browse by Subject")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(addMessage, isPresented: $showAddMessage) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private func searchBySubject() {
        let subject = subjectInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !subject.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        books = []

        let range = publishedIn.trimmingCharacters(in: .whitespaces)
        let publishedParam = range.isEmpty ? nil : range

        BookService.searchBySubject(subject: subject, publishedIn: publishedParam) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    books = items
                    if items.isEmpty {
                        errorMessage = "No books found for subject \"\(subject)\""
                    }
                case .failure(let message):
                    errorMessage = message
                }
            }
        }
    }

    private func addBookToLibrary(_ item: BookItem) {
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
        } catch {
            addMessage = "Could not save book: \(error.localizedDescription)"
        }
        showAddMessage = true
    }
}

private struct SubjectBookRow: View {
    let book: BookItem
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let urlString = book.volumeInfo.imageLinks?.thumbnail ?? book.volumeInfo.imageLinks?.smallThumbnail,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                placeholder
                    .frame(width: 50, height: 75)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.volumeInfo.title ?? "Unknown")
                    .font(.headline)
                if let authors = book.volumeInfo.authors?.joined(separator: ", ") {
                    Text(authors)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let published = book.volumeInfo.publishedDate {
                    Text("Published: \(published)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let subjects = book.volumeInfo.subjects?.prefix(3).joined(separator: ", ") {
                    Text(subjects)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    SubjectBrowseView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
