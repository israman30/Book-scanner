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

    init(
        id: UUID = UUID(),
        title: String,
        authors: String,
        isbn: String?,
        thumbnailURL: URL? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.isbn = isbn
        self.thumbnailURL = thumbnailURL
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
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

        self.init(
            title: title,
            authors: authors,
            isbn: isbn,
            thumbnailURL: thumbnailURL,
            publisher: publisher,
            publishedDate: publishedDate,
            description: description
        )
    }

    /// Google Books sometimes returns `http` URLs; upgrade them to https when possible.
    private static func normalize(urlString: String?) -> URL? {
        guard var urlString else { return nil }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        return URL(string: urlString)
    }
}
