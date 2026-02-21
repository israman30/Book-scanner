import Foundation

/// Container for Google Books API response.
struct Books: nonisolated Decodable {
    let items: [BookItem]?
}

/// Single book entry returned by the API.
struct BookItem: Decodable {
    let volumeInfo: VolumeInfo
}

/// Metadata we care about from Google Books volume info.
struct VolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
}

/// URLs for book artwork.
struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
}

/// Identifiers such as ISBN-10/ISBN-13.
struct IndustryIdentifier: Decodable {
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
    /// Queries Google Books by ISBN and returns either the first matched item
    /// or a user-facing error message via completion on any thread.
    static func search(isbn: String, completion: @escaping (BookResult) -> Void) {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)

        guard var url = URL(string: "https://www.googleapis.com/books/v1/volumes/") else {
            completion(.failure(BookServiceError.invalidURL.message))
            return
        }

        url.append(queryItems: [URLQueryItem(name: "q", value: "isbn:\(isbn)")])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                completion(.failure(BookServiceError.badStatus(code: httpResponse.statusCode).message))
                return
            }
            
            guard let data = data else {
                completion(.failure(BookServiceError.emptyResponseData.message))
                return
            }
            
            do {
                let bookData = try JSONDecoder().decode(Books.self, from: data)
                if let first = bookData.items?.first {
                    completion(.success(first))
                    BookService.logBookDetails(first)
                } else {
                    completion(.failure(BookServiceError.noBooksFound(isbn: isbn).message))
                }
            } catch {
                completion(.failure(BookServiceError.decodingFailed(error).message))
            }
        }
        task.resume()
    }

    /// Helper used for debugging to print book metadata when found.
    private static func logBookDetails(_ book: BookItem) {
        guard let title = book.volumeInfo.title,
              let authors = book.volumeInfo.authors,
              let publisher = book.volumeInfo.publisher,
              let description = book.volumeInfo.description,
              let publishedDate = book.volumeInfo.publishedDate else {
            return
        }

        let authorList = authors.joined(separator: ", ")
        print("""
        Book: \(title)
        author(s): \(authorList)
        publisher: \(publisher)
        published date: \(publishedDate)
        description: \(description)
        """)
    }
}
