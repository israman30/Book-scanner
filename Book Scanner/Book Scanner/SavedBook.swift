import Foundation

struct SavedBook: Identifiable, Equatable {
    let id: UUID
    var title: String
    var authors: String
    var isbn: String?

    init(id: UUID = UUID(), title: String, authors: String, isbn: String?) {
        self.id = id
        self.title = title
        self.authors = authors
        self.isbn = isbn
    }

    init(from item: BookItem) {
        let title = item.volumeInfo.title ?? "Untitled"
        let authors = item.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown author"
        let isbn = item.volumeInfo.industryIdentifiers?.first?.identifier

        self.init(title: title, authors: authors, isbn: isbn)
    }
}
