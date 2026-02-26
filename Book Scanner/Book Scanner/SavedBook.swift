import Foundation

struct SavedBook: Identifiable, Equatable {
    let id: UUID
    var title: String
    var authors: String
    var isbn: String?
    var thumbnailURL: URL?
    var publisher: String?
    var publishedDate: String?
    var description: String?
    var subjects: String?

    init(
        id: UUID = UUID(),
        title: String,
        authors: String,
        isbn: String?,
        thumbnailURL: URL? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        description: String? = nil,
        subjects: String? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.isbn = isbn
        self.thumbnailURL = thumbnailURL
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
        self.subjects = subjects
    }

    init(from item: BookItem) {
        let title = item.volumeInfo.title ?? "Untitled"
        let authors = item.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown author"
        let isbn = item.volumeInfo.industryIdentifiers?.first?.identifier
        let rawImageURL = item.volumeInfo.imageLinks?.smallThumbnail
            ?? item.volumeInfo.imageLinks?.thumbnail
        let thumbnailURL = SavedBook.normalize(urlString: rawImageURL)
        let publisher = item.volumeInfo.publisher
        let publishedDate = item.volumeInfo.publishedDate
        let description = item.volumeInfo.description
        let subjects = item.volumeInfo.subjects?.joined(separator: ", ")

        self.init(
            title: title,
            authors: authors,
            isbn: isbn,
            thumbnailURL: thumbnailURL,
            publisher: publisher,
            publishedDate: publishedDate,
            description: description,
            subjects: subjects
        )
    }

    /// Normalizes image URLs (e.g. upgrade http to https when possible).
    private static func normalize(urlString: String?) -> URL? {
        guard var urlString else { return nil }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        return URL(string: urlString)
    }
}
