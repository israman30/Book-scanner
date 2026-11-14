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
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showThumbnailFullScreen = false
    @State private var isbnCopied = false

    private let coverWidth: CGFloat = 160
    private let coverHeight: CGFloat = 240

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                coverHeaderSection
                titleSection
                quickActionsSection
                descriptionSection
                metadataSection
                isbnSection
                notesSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(AppConstants.Strings.bookDetails)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        shareItems = [exportSingleBook()]
                        showShareSheet = true
                    } label: {
                        Label(AppConstants.Strings.share, systemImage: AppConstants.Icons.squareAndArrowUp)
                    }
                    Button {
                        showEditSheet = true
                    } label: {
                        Label(AppConstants.Strings.edit, systemImage: AppConstants.Icons.pencil)
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(AppConstants.Strings.delete, systemImage: AppConstants.Icons.trash)
                    }
                } label: {
                    Image(systemName: AppConstants.Icons.ellipsisCircle)
                }
                .accessibilityLabel(AppConstants.Accessibility.bookActions)
            }
        }
        .confirmationDialog(AppConstants.Strings.deleteBook, isPresented: $showDeleteConfirmation) {
            Button(AppConstants.Strings.delete, role: .destructive) {
                deleteBook()
            }
            Button(AppConstants.Strings.cancel, role: .cancel) {}
        } message: {
            Text("Remove \"\(book.title ?? "")\" from your catalog? This cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showEditSheet) {
            BookEditSheet(book: book)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showThumbnailFullScreen) {
            if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
                ThumbnailView(url: url)
            }
        }
    }

    // MARK: - Cover Header

    private var coverHeaderSection: some View {
        VStack(spacing: 24) {
            if let urlString = book.thumbnailURLString, let url = URL(string: urlString) {
                coverImage(from: url)
            } else {
                placeholderCover
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }

    private func coverImage(from url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholderCover
                    .overlay { ProgressView() }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholderCover
            @unknown default:
                placeholderCover
            }
        }
        .frame(width: coverWidth, height: coverHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        .accessibilityLabel(AppConstants.Accessibility.bookCover)
        .onTapGesture {
            showThumbnailFullScreen = true
        }
    }

    private var placeholderCover: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: coverWidth, height: coverHeight)
            .overlay {
                Image(systemName: AppConstants.Icons.bookClosed)
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
            }
            .accessibilityLabel(AppConstants.Accessibility.bookCoverNoAvailable)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(book.title ?? "Untitled")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let authors = book.authors, !authors.isEmpty {
                Text("by \(authors)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 20) {
            QuickActionButton(
                title: AppConstants.Strings.share,
                icon: AppConstants.Icons.squareAndArrowUp,
                action: {
                    shareItems = [exportSingleBook()]
                    showShareSheet = true
                }
            )
            QuickActionButton(
                title: AppConstants.Strings.edit,
                icon: AppConstants.Icons.pencil,
                action: { showEditSheet = true }
            )
            QuickActionButton(
                title: AppConstants.Strings.delete,
                icon: AppConstants.Icons.trash,
                tint: .red,
                action: { showDeleteConfirmation = true }
            )
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        Group {
            if let description = book.bookDescription, !description.isEmpty {
                SectionView(title: AppConstants.Strings.description) {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        SectionView(title: AppConstants.Strings.metadata) {
            VStack(alignment: .leading, spacing: 14) {
                if let publisher = book.publisher, !publisher.isEmpty {
                    MetadataRow(label: AppConstants.Strings.publisher, value: publisher)
                }
                if let publishedDate = book.publishedDate {
                    MetadataRow(label: AppConstants.Strings.published, value: publishedDate)
                }
                if let subjects = book.subjects, !subjects.isEmpty {
                    subjectBadgesSection(subjects: subjects)
                }
                if (book.publisher?.isEmpty ?? true) &&
                   book.publishedDate == nil &&
                   (book.subjects?.isEmpty ?? true) {
                    Text(AppConstants.Strings.noMetdataAvailable)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func subjectBadgesSection(subjects: String) -> some View {
        let subjectList = subjects
            .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: 8) {
            Text(AppConstants.Strings.subjects)
                .font(.caption)
                .foregroundStyle(.tertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Use indices as IDs to avoid runtime issues if the stored string contains duplicates.
                    ForEach(Array(subjectList.enumerated()), id: \.offset) { _, subject in
                        Text(subject)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(softColorForSubject(subject).opacity(0.35))
                            )
                            .foregroundStyle(softColorForSubject(subject))
                    }
                }
            }
            .frame(height: 32)
        }
    }

    private func softColorForSubject(_ subject: String) -> Color {
        let palette: [Color] = [
            Color(red: 0.4, green: 0.6, blue: 0.9),
            Color(red: 0.4, green: 0.75, blue: 0.6),
            Color(red: 0.85, green: 0.55, blue: 0.4),
            Color(red: 0.65, green: 0.5, blue: 0.85),
            Color(red: 0.9, green: 0.5, blue: 0.6),
            Color(red: 0.4, green: 0.75, blue: 0.75),
            Color(red: 0.6, green: 0.65, blue: 0.9),
        ]
        let hash = abs(subject.hashValue)
        return palette[hash % palette.count]
    }

    // MARK: - ISBN

    private var isbnSection: some View {
        SectionView(title: AppConstants.Strings.isbn) {
            HStack {
                if let isbn = book.isbn, !isbn.isEmpty {
                    Text(isbn)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        copyISBNToClipboard(isbn)
                    } label: {
                        Label(
                            isbnCopied ? AppConstants.Strings.copied : AppConstants.Strings.copy,
                            systemImage: isbnCopied ? AppConstants.Icons.checkmarkCircleFill : AppConstants.Icons.docOnDoc
                        )
                        .font(.subheadline)
                        .foregroundStyle(isbnCopied ? .green : .accentColor)
                    }
                    .buttonStyle(.borderless)
                    .disabled(isbnCopied)
                    .accessibilityHint(AppConstants.Accessibility.copiesISBNtoClipboard)
                } else {
                    Text(AppConstants.Strings.noMetdataAvailable)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        Group {
            if let notes = book.notes, !notes.isEmpty {
                SectionView(title: AppConstants.Strings.notes) {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private func copyISBNToClipboard(_ isbn: String) {
        UIPasteboard.general.string = isbn
        isbnCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isbnCopied = false
        }
    }

    private func deleteBook() {
        viewContext.delete(book)
        PersistenceController.shared.save()
        dismiss()
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

// MARK: - Section View

private struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let title: String
    let icon: String
    var tint: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book Edit Sheet

private struct BookEditSheet: View {
    @ObservedObject var book: BookEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(AppConstants.Strings.bookInfo) {
                    TextField(AppConstants.Strings.title, text: Binding(
                        get: { book.title ?? "" },
                        set: { book.title = $0 }
                    ))
                    TextField(AppConstants.Strings.authors, text: Binding(
                        get: { book.authors ?? "" },
                        set: { book.authors = $0 }
                    ))
                }
                Section(AppConstants.Strings.notes) {
                    TextEditor(text: Binding(
                        get: { book.notes ?? "" },
                        set: { book.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                    .font(.body)
                    .overlay(alignment: .topLeading) {
                        if (book.notes ?? "").isEmpty {
                            Text(AppConstants.Strings.addYourThoughtsHighlights)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .navigationTitle(AppConstants.Strings.editBook)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppConstants.Strings.cancel) {
                        viewContext.rollback()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppConstants.Strings.save) {
                        PersistenceController.shared.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet

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
