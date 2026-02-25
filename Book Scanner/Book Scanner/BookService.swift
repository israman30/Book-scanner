import Foundation

// MARK: - Open Library API

/// Response from Open Library search API: https://openlibrary.org/search.json
struct OpenLibrarySearchResponse: nonisolated Decodable {
    let numFound: Int
    let docs: [OpenLibraryDoc]
}

/// Single book document from Open Library search.
struct OpenLibraryDoc: Decodable {
    let title: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let isbn: [String]?
    let publisher: [String]?
    let publishDate: [String]?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case isbn
        case publisher
        case publishDate = "publish_date"
    }
}

// MARK: - App model (unified representation)

/// Single book entry used across the app (mapped from Open Library or other sources).
struct BookItem {
    let volumeInfo: VolumeInfo
}

/// Metadata we care about for display and saving.
struct VolumeInfo {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
}

/// URLs for book artwork.
struct ImageLinks {
    let smallThumbnail: String?
    let thumbnail: String?
}

/// Identifiers such as ISBN-10/ISBN-13.
struct IndustryIdentifier {
    let type: String
    let identifier: String
}

enum BookServiceError: Error {
    case invalidURL
    case network(Error)
    case invalidResponse
    case badStatus(code: Int)
    case emptyResponseData
    case decodingFailed(Error)
    case noBooksFound(isbn: String)

    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response received from server"
        case .badStatus(let code):
            return "Bad status code: \(code)"
        case .emptyResponseData:
            return "No data returned"
        case .decodingFailed:
            return "Error decoding book data"
        case .noBooksFound(let isbn):
            return "No books found for ISBN \(isbn)"
        }
    }
}

enum BookResult {
    case success(BookItem)
    case failure(String)
}

final class BookService {
    /// Queries Open Library by ISBN and returns either the first matched item or a
    /// user-facing error message via completion on any thread.
    /// Uses: https://openlibrary.org/search.json?q=isbn:{isbn}
    static func search(isbn: String, completion: @escaping (BookResult) -> Void) {
        search(query: "isbn:\(isbn)", fallbackIsbn: isbn, completion: completion)
    }

    /// Queries Open Library by general search (title, author, etc).
    /// Uses: https://openlibrary.org/search.json?q={query}
    static func search(query: String, completion: @escaping (BookResult) -> Void) {
        search(query: query, fallbackIsbn: nil, completion: completion)
    }

    @MainActor
    private static func search(query: String, fallbackIsbn: String?, completion: @escaping (BookResult) -> Void) {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)

        guard var url = URL(string: "https://openlibrary.org/search.json") else {
            completion(.failure(BookServiceError.invalidURL.message))
            return
        }

        url.append(queryItems: [URLQueryItem(name: "q", value: query)])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("BookScanner/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) {
            data,
            response,
            error in
            if let error {
                completion(.failure(BookServiceError.network(error).message))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(BookServiceError.invalidResponse.message))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                #if DEBUG
                if let bodyData = data, let body = String(data: bodyData, encoding: .utf8) {
                    print("[BookService] Bad status \(httpResponse.statusCode): \(body.prefix(500))")
                }
                #endif
                completion(.failure(BookServiceError.badStatus(code: httpResponse.statusCode).message))
                return
            }

            guard let data = data else {
                completion(.failure(BookServiceError.emptyResponseData.message))
                return
            }

            do {
                let searchResponse = try JSONDecoder().decode(OpenLibrarySearchResponse.self, from: data)
                if let firstDoc = searchResponse.docs.first {
                    let bookItem = BookService.mapToBookItem(doc: firstDoc, searchIsbn: fallbackIsbn)
                    completion(.success(bookItem))
                    BookService.logBookDetails(bookItem)
                } else {
                    let msg = fallbackIsbn.map { BookServiceError.noBooksFound(isbn: $0).message }
                        ?? "No books found for \"\(query)\""
                    completion(.failure(msg))
                }
            } catch {
                completion(.failure(BookServiceError.decodingFailed(error).message))
            }
        }
        task.resume()
    }

    /// Maps an Open Library doc to the app's BookItem model.
    private static func mapToBookItem(doc: OpenLibraryDoc, searchIsbn: String?) -> BookItem {
        let isbn = doc.isbn?.first ?? searchIsbn
        let thumbnailURL: String?
        if let coverI = doc.coverI {
            thumbnailURL = "https://covers.openlibrary.org/b/id/\(coverI)-M.jpg"
        } else {
            thumbnailURL = nil
        }
        let imageLinks = ImageLinks(
            smallThumbnail: thumbnailURL,
            thumbnail: thumbnailURL
        )
        let industryIdentifiers = isbn.map { [IndustryIdentifier(type: "ISBN_13", identifier: $0)] }
        let publishedDate = doc.firstPublishYear.map { String($0) }
            ?? doc.publishDate?.first
        let publisher = doc.publisher?.joined(separator: ", ")

        let volumeInfo = VolumeInfo(
            title: doc.title,
            authors: doc.authorName,
            publisher: publisher,
            publishedDate: publishedDate,
            description: nil,
            imageLinks: imageLinks,
            industryIdentifiers: industryIdentifiers
        )
        return BookItem(volumeInfo: volumeInfo)
    }

    /// Helper used for debugging to print book metadata when found.
    private static func logBookDetails(_ book: BookItem) {
        guard let title = book.volumeInfo.title else { return }
        let authorList = book.volumeInfo.authors?.joined(separator: ", ") ?? "—"
        let publisher = book.volumeInfo.publisher ?? "—"
        let publishedDate = book.volumeInfo.publishedDate ?? "—"
        let description = book.volumeInfo.description ?? "—"
        print("""
        Book: \(title)
        author(s): \(authorList)
        publisher: \(publisher)
        published date: \(publishedDate)
        description: \(description)
        """)
    }
}

