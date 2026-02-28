//
//  SavedBookCardView.swift
//  Book Scanner
//
//  Created by Israel Manzo on 2/21/26.
//

import SwiftUI
import CoreData

struct SavedBookCardView: View {
    let book: BookEntity

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let url = book.thumbnailURLString.flatMap({ URL(string: $0) }) {
                asyncImageThumbnail(with: url)
            } else {
                placeholder
                    .frame(width: 60, height: 90)
                    .accessibilityHidden(true)
            }

            bodyCard
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
    
    private func asyncImageThumbnail(with url: URL) -> some View {
        AsyncImage(url: thumbnailURLForList(from: url)) { phase in
            switch phase {
            case .empty:
                placeholder
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .contentTransition(.opacity)
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }
    
    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(book.title ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Spacer(minLength: 4)
                if book.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.pink)
                }
            }
            Text(book.authors ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let isbn = book.isbn {
                Text("ISBN: \(isbn)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if let subjects = book.subjects, !subjects.isEmpty {
                subjectTagsView(subjects: subjects)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(book.title ?? "")
        .accessibilityValue(accessibilitySummary(for: book))
    }

    private func accessibilitySummary(for book: BookEntity) -> String {
        var parts = ["Authors \(book.authors ?? "")"]
        if let isbn = book.isbn {
            parts.append("ISBN \(isbn)")
        }
        return parts.joined(separator: ". ")
    }

    private func subjectTagsView(subjects: String) -> some View {
        let subjectList = subjects
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(subjectList, id: \.self) { subject in
                    Text(subject)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(colorForSubject(subject).opacity(0.25))
                        .foregroundStyle(colorForSubject(subject))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(height: 28)
    }

    private func colorForSubject(_ subject: String) -> Color {
        let palette: [Color] = [
            .blue, .green, .orange, .purple, .pink, .teal,
            .mint, .indigo, .red, .cyan, .brown
        ]
        let hash = abs(subject.hashValue)
        let index = hash % palette.count
        return palette[index]
    }

    /// Returns a smaller thumbnail URL for list display to improve load time.
    private func thumbnailURLForList(from url: URL) -> URL {
        let absolute = url.absoluteString
        if absolute.contains("covers.openlibrary.org"),
           let range = absolute.range(of: "-[ML]\\.jpg$", options: .regularExpression) {
            var modified = absolute
            modified.replaceSubrange(range, with: "-S.jpg")
            return URL(string: modified) ?? url
        }
        return url
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Grid Cell (cover-focused)

struct SavedBookGridCellView: View {
    let book: BookEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            coverView
            Text(book.title ?? "")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coverView: some View {
        Group {
            if let url = book.thumbnailURLString.flatMap({ URL(string: $0) }) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                            .overlay { ProgressView() }
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
            } else {
                placeholder
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topTrailing) {
            if book.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                    .padding(6)
            }
        }
    }

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
    let sample = SavedBook(title: "The Pragmatic Programmer", authors: "Andrew Hunt, David Thomas", isbn: "978-0201616224", publisher: "Addison-Wesley Professional", publishedDate: "1999", description: "One of the most significant books in my life.", subjects: "Programming, Software Development, Best Practices")
    let book = BookEntity.create(from: sample, in: context)
    try? context.save()

    return SavedBookCardView(book: book)
        .padding()
        .environment(\.managedObjectContext, context)
}
