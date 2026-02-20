import Foundation

struct Books: nonisolated Decodable {
    let items: [BookItem]?
}

struct BookItem: Decodable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
}

struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
}

struct IndustryIdentifier: Decodable {
    let type: String
    let identifier: String
}

enum BookServiceError: Error {
    case invalidURL
    case badStatus(code: Int)
    case emptyResponse
    case decodingFailed
}

enum BookResult {
    case success(BookItem)
    case failure(String)
}

final class BookService {
    static func search(isbn: String, completion: @escaping (BookResult) -> Void) {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)

        guard var url = URL(string: "https://www.googleapis.com/books/v1/volumes/") else {
            completion(.failure("Invalid URL"))
            return
        }

        url.append(queryItems: [URLQueryItem(name: "q", value: "isbn:\(isbn)")])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure("Network error: \(error.localizedDescription)"))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure("Bad status code: \(httpResponse.statusCode)"))
                return
            }

            guard let data = data else {
                completion(.failure("No data returned"))
                return
            }

            do {
                let bookData = try JSONDecoder().decode(Books.self, from: data)
                if let first = bookData.items?.first {
                    completion(.success(first))
                    print("Book: \(first.volumeInfo)")
                } else {
                    completion(.failure("No books found for ISBN \(isbn)"))
                }
            } catch {
                completion(.failure("Error decoding book data"))
            }
        }
        task.resume()
    }
}
