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
    let subject: [String]?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case isbn
        case publisher
        case publishDate = "publish_date"
        case subject
    }
}

// MARK: - Open Library Subjects API

/// Response from Open Library subjects API: https://openlibrary.org/subjects/{subject}.json
/// Example: https://openlibrary.org/subjects/love.json?published_in=1500-1600
struct OpenLibrarySubjectsResponse: Decodable {
    let name: String
    let workCount: Int
    let works: [OpenLibrarySubjectWork]

    enum CodingKeys: String, CodingKey {
        case name
        case workCount = "work_count"
        case works
    }
}

/// Single work from the subjects API response.
struct OpenLibrarySubjectWork: Decodable {
    let key: String
    let title: String
    let coverId: Int?
    let coverEditionKey: String?
    let subject: [String]
    let authors: [OpenLibrarySubjectAuthor]
    let firstPublishYear: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case coverId = "cover_id"
        case coverEditionKey = "cover_edition_key"
        case subject
        case authors
        case firstPublishYear = "first_publish_year"
    }
}

struct OpenLibrarySubjectAuthor: Decodable {
    let name: String
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
    let subjects: [String]?
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

/// Result for subject-based search returning multiple books.
enum BookListResult {
    case success([BookItem])
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

    /// Fetches books by subject from the Open Library subjects API.
    /// Uses: https://openlibrary.org/subjects/{subject}.json?published_in={range}
    /// - Parameters:
    ///   - subject: Subject name (e.g. "love", "science", "fiction")
    ///   - publishedIn: Optional date range (e.g. "1500-1600")
    ///   - completion: Called with an array of BookItems or an error string.
    static func searchBySubject(
        subject: String,
        publishedIn: String? = nil,
        completion: @escaping (BookListResult) -> Void
    ) {
        guard var url = URL(string: "https://openlibrary.org/subjects/\(subject).json") else {
            completion(.failure(BookServiceError.invalidURL.message))
            return
        }
        if let range = publishedIn, !range.isEmpty {
            url.append(queryItems: [URLQueryItem(name: "published_in", value: range)])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("BookScanner/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(BookServiceError.network(error).message))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(BookServiceError.invalidResponse.message))
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(BookServiceError.badStatus(code: httpResponse.statusCode).message))
                return
            }
            guard let data else {
                completion(.failure(BookServiceError.emptyResponseData.message))
                return
            }
            do {
                let subjectsResponse = try JSONDecoder().decode(OpenLibrarySubjectsResponse.self, from: data)
                let books = subjectsResponse.works.map { BookService.mapSubjectWorkToBookItem($0) }
                completion(.success(books))
            } catch {
                completion(.failure(BookServiceError.decodingFailed(error).message))
            }
        }
        task.resume()
    }

    /// Maps an Open Library subject work to the app's BookItem model.
    private static func mapSubjectWorkToBookItem(_ work: OpenLibrarySubjectWork) -> BookItem {
        let thumbnailURL: String?
        if let coverId = work.coverId {
            thumbnailURL = "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
        } else {
            thumbnailURL = nil
        }
        let imageLinks = ImageLinks(
            smallThumbnail: thumbnailURL,
            thumbnail: thumbnailURL
        )
        let authorNames = work.authors.map { $0.name }
        let publishedDate = work.firstPublishYear.map { String($0) }
        let volumeInfo = VolumeInfo(
            title: work.title,
            authors: authorNames.isEmpty ? nil : authorNames,
            publisher: nil,
            publishedDate: publishedDate,
            description: nil,
            imageLinks: imageLinks,
            industryIdentifiers: nil,
            subjects: work.subject.isEmpty ? nil : work.subject
        )
        return BookItem(volumeInfo: volumeInfo)
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
                    print("Book Object: \(bookItem)")
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
            industryIdentifiers: industryIdentifiers,
            subjects: doc.subject
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

