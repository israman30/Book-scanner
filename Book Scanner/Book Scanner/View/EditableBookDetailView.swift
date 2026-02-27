//
//  EditableBookDetailView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/26/26.
//

import SwiftUI
import CoreData
import UIKit

struct EditableBookDetailView: View {
    @ObservedObject var book: BookEntity
    @Environment(\.managedObjectContext) private var viewContext
    @State var isPresented = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        Form {
            Section("Cover") {
                HStack {
                    Spacer()
                    if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
                        asyncImageThumbnail(with: url)
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

            Section("Notes") {
                TextEditor(text: Binding(
                    get: { book.notes ?? "" },
                    set: { book.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
                .font(.body)
                .overlay(alignment: .topLeading) {
                    if (book.notes ?? "").isEmpty {
                        Text("Add your thoughts, highlights, or reminders about this book…")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .navigationTitle("Edit Book")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareItems = [exportSingleBook()]
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .accessibilityLabel("Share book")
                .accessibilityHint("Share this book with family and friends")
            }
        }
        .onDisappear {
            PersistenceController.shared.save()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $isPresented) {
            if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
                ThumbnailView(url: url)
            }
        }
    }
    
    private func asyncImageThumbnail(with url: URL) -> some View {
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

    private func exportSingleBook() -> URL {
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
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

