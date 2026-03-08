//
//  SubjectBrowseView.swift
//  Book Scanner
//
//  Browse books by ISBN, author, title, or subject using Open Library APIs.
//

import SwiftUI
import CoreData

struct SubjectBrowseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SubjectBrowseViewModel

    init(viewContext: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SubjectBrowseViewModel(viewContext: viewContext))
    }

    @ViewBuilder
    private func styledTextField(
        placeholder: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)

            TextField(placeholder, text: text)

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4).opacity(0.6), lineWidth: 1)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Search by")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Search type", selection: $viewModel.searchType) {
                        ForEach(SearchType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(viewModel.searchType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    styledTextField(
                        placeholder: viewModel.searchPlaceholder,
                        text: $viewModel.searchInput,
                        icon: viewModel.searchType == .isbn ? "barcode" : "magnifyingglass"
                    )
                    .autocapitalization(.none)
                    .keyboardType(viewModel.searchType == .isbn ? .numbersAndPunctuation : .default)
                    .submitLabel(.search)
                    .onSubmit { viewModel.performSearch() }

                    if viewModel.searchType == .subject {
                        Text("Published in (optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        styledTextField(
                            placeholder: "e.g. 1500-1600 or leave empty",
                            text: $viewModel.publishedIn,
                            icon: "calendar"
                        )
                        .keyboardType(.numbersAndPunctuation)
                        .submitLabel(.search)
                        .onSubmit { viewModel.performSearch() }
                    }
                }
                .padding(.horizontal, 20)

                Button {
                    viewModel.performSearch()
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Search")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .disabled(viewModel.isSearchDisabled)
                .padding(.horizontal, 20)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                }

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.books.enumerated()), id: \.offset) { _, book in
                            SubjectBookRow(
                                book: book,
                                didJustAdd: viewModel.justAddedTitle == book.volumeInfo.title
                            ) {
                                viewModel.addBookToLibrary(book)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Browse Books")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(viewModel.addMessage, isPresented: $viewModel.showAddMessage) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

private struct SubjectBookRow: View {
    let book: BookItem
    var didJustAdd: Bool = false
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
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
                .frame(width: 56, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                placeholder
                    .frame(width: 56, height: 84)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(book.volumeInfo.title ?? "Unknown")
                    .font(.headline)
                    .fontWeight(.semibold)
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
                if let subjects = book.volumeInfo.subjects, !subjects.isEmpty {
                    subjectBadgesView(subjects: Array(subjects.prefix(3)))
                }
            }

            Spacer(minLength: 8)

            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(didJustAdd ? 1.02 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: didJustAdd)
    }

    private func subjectBadgesView(subjects: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(subjects, id: \.self) { subject in
                    Text(subject)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(softColorForSubject(subject).opacity(0.35))
                        )
                        .foregroundStyle(softColorForSubject(subject))
                }
            }
        }
        .frame(height: 28)
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

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .overlay {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    SubjectBrowseView(viewContext: PersistenceController.preview.viewContext)
}
