//
//  CollectionStatsView.swift
//  Book Scanner
//
//  Simple stats dashboard for the book collection.
//

import SwiftUI
import CoreData

struct CollectionStatsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.title, ascending: true)],
        animation: .default
    )
    private var savedBooks: FetchedResults<BookEntity>

    private var totalBooks: Int { savedBooks.count }

    private var subjectCounts: [(subject: String, count: Int)] {
        var counts: [String: Int] = [:]
        for book in savedBooks {
            guard let subjects = book.subjects, !subjects.isEmpty else { continue }
            let list = subjects
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            for subject in list {
                counts[subject, default: 0] += 1
            }
        }
        return counts
            .map { (subject: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var mostOwnedSubject: (subject: String, count: Int)? {
        subjectCounts.first
    }

    private var recentlyAdded: [BookEntity] {
        savedBooks
            .filter { $0.addedDate != nil }
            .sorted { ($0.addedDate ?? .distantPast) > ($1.addedDate ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        if savedBooks.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Collection")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    statCard(
                        value: "\(totalBooks)",
                        label: "Total books",
                        icon: "books.vertical"
                    )
                    if let top = mostOwnedSubject {
                        statCard(
                            value: top.subject,
                            label: "Top subject (\(top.count))",
                            icon: "tag.fill"
                        )
                    }
                }

                if !subjectCounts.isEmpty {
                    subjectsSection
                }
                if !recentlyAdded.isEmpty {
                    recentlyAddedSection
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private var subjectsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Books per subject")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(subjectCounts.prefix(8), id: \.subject) { item in
                        HStack(spacing: 6) {
                            Text(item.subject)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("\(item.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }
            }
        }
    }

    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently added")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(recentlyAdded, id: \.objectID) { book in
                    HStack(spacing: 10) {
                        if let url = book.thumbnailURLString.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: recentPlaceholder
                                }
                            }
                            .frame(width: 36, height: 52)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            recentPlaceholder
                                .frame(width: 36, height: 52)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            if let date = book.addedDate {
                                Text(relativeDate(from: date))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
            }
        }
    }

    private var recentPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
    }

    private func relativeDate(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let controller = PersistenceController(inMemory: true)
    let context = controller.viewContext
    for (i, sample) in [
        SavedBook(title: "The Pragmatic Programmer", authors: "Andrew Hunt, David Thomas", isbn: "978-0201616224", subjects: "Programming, Software Development"),
        SavedBook(title: "Clean Code", authors: "Robert C. Martin", isbn: "978-0132350884", subjects: "Programming, Refactoring"),
        SavedBook(title: "SwiftUI Essentials", authors: "Apple", isbn: nil, subjects: "Swift, iOS, Programming")
    ].enumerated() {
        let book = BookEntity.create(from: sample, in: context)
        book.addedDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())
    }
    try? context.save()

    return ScrollView {
        CollectionStatsView()
            .padding()
    }
    .environment(\.managedObjectContext, context)
}
