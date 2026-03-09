//
//  SubjectBrowseViewModelTests.swift
//  Book ScannerTests
//
//  Unit tests for SubjectBrowseViewModel.
//

import XCTest
import CoreData
@testable import Book_Scanner

@MainActor
final class SubjectBrowseViewModelTests: XCTestCase {

    var viewModel: SubjectBrowseViewModel!
    var viewContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        viewContext = PersistenceController.preview.viewContext
        viewModel = SubjectBrowseViewModel(viewContext: viewContext)
    }

    override func tearDown() {
        viewModel = nil
        viewContext = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_InitialState() {
        XCTAssertEqual(viewModel.searchType, .title)
        XCTAssertEqual(viewModel.searchInput, "")
        XCTAssertEqual(viewModel.publishedIn, "")
        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.addMessage, "")
        XCTAssertFalse(viewModel.showAddMessage)
        XCTAssertNil(viewModel.justAddedTitle)
    }

    // MARK: - searchPlaceholder

    func test_searchPlaceholder_isbn() {
        viewModel.searchType = .isbn
        XCTAssertEqual(viewModel.searchPlaceholder, "e.g. 978-0-385-50420-5")
    }

    func test_searchPlaceholder_author() {
        viewModel.searchType = .author
        XCTAssertEqual(viewModel.searchPlaceholder, "e.g. Jane Austen")
    }

    func test_searchPlaceholder_title() {
        viewModel.searchType = .title
        XCTAssertEqual(viewModel.searchPlaceholder, "e.g. Pride and Prejudice")
    }

    func test_searchPlaceholder_subject() {
        viewModel.searchType = .subject
        XCTAssertEqual(viewModel.searchPlaceholder, "e.g. love, science, fiction")
    }

    // MARK: - isSearchDisabled

    func test_isSearchDisabled_whenLoading() {
        viewModel.searchInput = "valid query"
        viewModel.isLoading = true
        XCTAssertTrue(viewModel.isSearchDisabled)
    }

    func test_isSearchDisabled_whenInputEmpty() {
        viewModel.searchInput = ""
        viewModel.isLoading = false
        XCTAssertTrue(viewModel.isSearchDisabled)
    }

    func test_isSearchDisabled_whenInputWhitespaceOnly() {
        viewModel.searchInput = "   \t  "
        viewModel.isLoading = false
        XCTAssertTrue(viewModel.isSearchDisabled)
    }

    func test_isSearchDisabled_whenInputPresentAndNotLoading() {
        viewModel.searchInput = "Pride and Prejudice"
        viewModel.isLoading = false
        XCTAssertFalse(viewModel.isSearchDisabled)
    }

    func test_isSearchDisabled_whenInputHasLeadingTrailingSpaces() {
        viewModel.searchInput = "  valid  "
        viewModel.isLoading = false
        XCTAssertFalse(viewModel.isSearchDisabled)
    }

    // MARK: - performSearch (empty input early return)

    func test_performSearch_withEmptyInput_doesNothing() {
        viewModel.searchInput = ""
        viewModel.performSearch()

        // Give async task a moment; with empty input it returns immediately
        let expectation = expectation(description: "Search completes")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_performSearch_withWhitespaceOnlyInput_doesNothing() {
        viewModel.searchInput = "   "
        viewModel.performSearch()

        let expectation = expectation(description: "Search completes")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        XCTAssertTrue(viewModel.books.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - addBookToLibrary

    func test_addBookToLibrary_addsNewBook() {
        let bookItem = makeBookItem(title: "Test Book", authors: "Test Author", isbn: "978-1234567890")
        viewModel.addBookToLibrary(bookItem)

        XCTAssertEqual(viewModel.addMessage, "\"Test Book\" added to your list.")
        XCTAssertTrue(viewModel.showAddMessage)
        XCTAssertEqual(viewModel.justAddedTitle, "Test Book")

        // Verify persisted in Core Data
        let request = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isbn == %@", "978-1234567890")
        request.fetchLimit = 1
        let results = try? viewContext.fetch(request)
        XCTAssertEqual(results?.count, 1)
        XCTAssertEqual(results?.first?.title, "Test Book")
    }

    func test_addBookToLibrary_duplicateShowsMessage() {
        let bookItem = makeBookItem(title: "Duplicate Book", authors: "Author", isbn: "978-1111111111")
        viewModel.addBookToLibrary(bookItem)
        viewModel.showAddMessage = false

        viewModel.addBookToLibrary(bookItem)

        XCTAssertEqual(viewModel.addMessage, "This book is already in your list.")
        XCTAssertTrue(viewModel.showAddMessage)

        // Should still have only one book in store
        let request = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isbn == %@", "978-1111111111")
        let results = try? viewContext.fetch(request)
        XCTAssertEqual(results?.count, 1)
    }

    func test_addBookToLibrary_bookWithoutIsbn_addsSuccessfully() {
        let bookItem = makeBookItem(title: "No ISBN Book", authors: "Author", isbn: nil)
        viewModel.addBookToLibrary(bookItem)

        XCTAssertEqual(viewModel.addMessage, "\"No ISBN Book\" added to your list.")
        XCTAssertTrue(viewModel.showAddMessage)

        let request = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", "No ISBN Book")
        let results = try? viewContext.fetch(request)
        XCTAssertEqual(results?.count, 1)
    }

    // MARK: - Helpers

    private func makeBookItem(title: String, authors: String, isbn: String?) -> BookItem {
        let identifiers: [IndustryIdentifier]? = isbn.map { [IndustryIdentifier(type: "ISBN_13", identifier: $0)] }
        let volumeInfo = VolumeInfo(
            title: title,
            authors: [authors],
            publisher: nil,
            publishedDate: nil,
            description: nil,
            imageLinks: nil,
            industryIdentifiers: identifiers,
            subjects: nil
        )
        return BookItem(volumeInfo: volumeInfo)
    }
}
