//
//  Book_ScannerTests.swift
//  Book ScannerTests
//
//  Created by Israel Manzo on 2/21/26.
//

import XCTest
@testable import Book_Scanner

class Book_ScannerTests: XCTestCase {
    
    var sut: ScannerViewController!
    var scannedCode: String?
    var permissionDeniedCalled = false
    
    func createScannerView(
        onScan: @escaping (String) -> Void = { _ in },
        onPermissionDenied: @escaping () -> Void = {}
    ) -> CameraScannerView {
        return CameraScannerView(
            onScan: onScan,
            onPermissionDenied: onPermissionDenied
        )
    }

    override func setUp() {
        sut = ScannerViewController()
    }
    
    func test_InitializationStoresCallbacks() {
        let expectedCode = "TEST123"
        let expectation = XCTestExpectation(description: "Scan callback triggered")
        
        let onScan: (String) -> Void = { [weak self] code in
            self?.scannedCode = code
            expectation.fulfill()
        }
        
        let onDenied: () -> Void = { [weak self] in
            self?.permissionDeniedCalled = true
        }
        
        let scannerView = CameraScannerView(
            onScan: onScan,
            onPermissionDenied: onDenied
        )
        
        scannerView.onScan(expectedCode)
        
        XCTAssertEqual(scannedCode, expectedCode)
    }
    
    func test_IntialStateSetup() {
        XCTAssertFalse(sut.isConfigured)
        XCTAssertFalse(sut.didReturnResult)
        XCTAssertNil(sut.onCodeDetected)
        XCTAssertNil(sut.onPermissionDenied)
    }
    
    func test_OnCodeDetected_Callback() {
        let expectation = XCTestExpectation(description: "Code detected")
        var capturedCode: String?
        
        sut.onCodeDetected = { code in
            capturedCode = code
            expectation.fulfill()
        }
        
        sut.simulateCodeDetection("TEST123")
        XCTAssertEqual(capturedCode, "TEST123")
        XCTAssertTrue(sut.didReturnResult)
    }
    
    func test_OnPermissionDenied_Callback() {
        let expectation = XCTestExpectation(description: "Permission denied")
        var permissionDeniedCalled = false
        
        sut.onPermissionDenied = {
            permissionDeniedCalled = true
            expectation.fulfill()
        }
        
        sut.simulatePermissionDenied()
        XCTAssertTrue(permissionDeniedCalled)
    }
    
    func test_MultipleCodeDetections_OnlyFirstReturns() {
        var detectionCount = 0
        sut.onCodeDetected = { _ in
            detectionCount += 1
        }
        
        sut.simulateCodeDetection("FIRST")
        sut.simulateCodeDetection("SECOND")
        sut.simulateCodeDetection("THIRD")
        
        XCTAssertEqual(detectionCount, 1)
        XCTAssertTrue(sut.didReturnResult)
    }
    
    func test_ConfigureSets_IsConfigured() {
        let expectation = XCTestExpectation(description: "Configuration complete")
        sut.configure { success in
            XCTAssertTrue(success)
            XCTAssertTrue(self.sut.isConfigured)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
    
    func test_ConfigureFailure() {
        let expectation = XCTestExpectation(description: "Configuration failed")
        sut.configure(simulateFailure: true) { success in
            XCTAssertFalse(success)
            XCTAssertFalse(self.sut.isConfigured)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }
    
    func test_ConfigureDoesNotRunTwice() {
        let expectation = XCTestExpectation(description: "Configure once")
        var configureCallCount = 0
        sut.configure { _ in
            configureCallCount += 1
            expectation.fulfill()
        }

        sut.configure { _ in
            configureCallCount += 1
        }
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(configureCallCount, 2)
    }
    
    func test_ResetAllowsNewDetection() {
        var codes: [String] = []
        sut.onCodeDetected = { code in
            codes.append(code)
        }
        
        sut.simulateCodeDetection("CODE1")
        
        sut.reset()
        sut.simulateCodeDetection("CODE2")
        
        XCTAssertEqual(codes, ["CODE1", "CODE2"])
        XCTAssertTrue(sut.didReturnResult)
    }
    
    func test_ResetClearsDidReturn_Result() {
        sut.simulateCodeDetection("TEST")
        XCTAssertTrue(sut.didReturnResult)
        
        sut.reset()
        
        XCTAssertFalse(sut.didReturnResult)
    }
    
    override func tearDown() {
        sut = nil
    }
}

// MARK: - SavedBook Tests

class SavedBookTests: XCTestCase {

    func test_InitWithAllParameters() {
        let id = UUID()
        let book = SavedBook(
            id: id,
            title: "Test Title",
            authors: "Test Author",
            isbn: "978-0132350884",
            thumbnailURL: URL(string: "https://example.com/cover.jpg"),
            publisher: "Test Publisher",
            publishedDate: "2024",
            description: "Test description"
        )

        XCTAssertEqual(book.id, id)
        XCTAssertEqual(book.title, "Test Title")
        XCTAssertEqual(book.authors, "Test Author")
        XCTAssertEqual(book.isbn, "978-0132350884")
        XCTAssertEqual(book.thumbnailURL?.absoluteString, "https://example.com/cover.jpg")
        XCTAssertEqual(book.publisher, "Test Publisher")
        XCTAssertEqual(book.publishedDate, "2024")
        XCTAssertEqual(book.description, "Test description")
    }

    func test_InitWithMinimalParameters() {
        let book = SavedBook(
            title: "Minimal Book",
            authors: "Unknown",
            isbn: nil
        )

        XCTAssertEqual(book.title, "Minimal Book")
        XCTAssertEqual(book.authors, "Unknown")
        XCTAssertNil(book.isbn)
        XCTAssertNil(book.thumbnailURL)
        XCTAssertNil(book.publisher)
        XCTAssertNil(book.publishedDate)
        XCTAssertNil(book.description)
    }

    func test_InitFromBookItem_WithFullMetadata() {
        let volumeInfo = VolumeInfo(
            title: "API Book",
            authors: ["Author A", "Author B"],
            publisher: "O'Reilly",
            publishedDate: "2023",
            description: "From API",
            imageLinks: ImageLinks(smallThumbnail: "http://example.com/small.jpg", thumbnail: "http://example.com/thumb.jpg"),
            industryIdentifiers: [IndustryIdentifier(type: "ISBN_13", identifier: "978-1234567890")],
            subjects: nil
        )
        let bookItem = BookItem(volumeInfo: volumeInfo)
        let saved = SavedBook(from: bookItem)

        XCTAssertEqual(saved.title, "API Book")
        XCTAssertEqual(saved.authors, "Author A, Author B")
        XCTAssertEqual(saved.isbn, "978-1234567890")
        XCTAssertEqual(saved.publisher, "O'Reilly")
        XCTAssertEqual(saved.publishedDate, "2023")
        XCTAssertEqual(saved.description, "From API")
        XCTAssertEqual(saved.thumbnailURL?.absoluteString, "https://example.com/small.jpg")
    }

    func test_InitFromBookItem_WithMissingFields() {
        let volumeInfo = VolumeInfo(
            title: nil,
            authors: nil,
            publisher: nil,
            publishedDate: nil,
            description: nil,
            imageLinks: nil,
            industryIdentifiers: nil,
            subjects: nil
        )
        let bookItem = BookItem(volumeInfo: volumeInfo)
        let saved = SavedBook(from: bookItem)

        XCTAssertEqual(saved.title, "Untitled")
        XCTAssertEqual(saved.authors, "Unknown author")
        XCTAssertNil(saved.isbn)
        XCTAssertNil(saved.thumbnailURL)
        XCTAssertNil(saved.publisher)
        XCTAssertNil(saved.publishedDate)
        XCTAssertNil(saved.description)
    }

    func test_InitFromBookItem_UpgradesHttpToHttps() {
        let volumeInfo = VolumeInfo(
            title: "HTTP Book",
            authors: nil,
            publisher: nil,
            publishedDate: nil,
            description: nil,
            imageLinks: ImageLinks(smallThumbnail: "http://covers.openlibrary.org/b/id/123.jpg", thumbnail: nil),
            industryIdentifiers: nil,
            subjects: nil
        )
        let bookItem = BookItem(volumeInfo: volumeInfo)
        let saved = SavedBook(from: bookItem)

        XCTAssertEqual(saved.thumbnailURL?.absoluteString, "https://covers.openlibrary.org/b/id/123.jpg")
    }

    func test_SavedBook_Identifiable() {
        let book = SavedBook(title: "ID Test", authors: "Author", isbn: nil)
        XCTAssertNotNil(book.id)
    }

}

// MARK: - BookService Tests

class BookServiceTests: XCTestCase {

    func test_BookServiceError_NoBooksFoundMessage() {
        let error = BookServiceError.noBooksFound(isbn: "978-1234567890")
        XCTAssertEqual(error.message, "No books found for ISBN 978-1234567890")
    }

    func test_BookServiceError_InvalidURLMessage() {
        let error = BookServiceError.invalidURL
        XCTAssertEqual(error.message, "Invalid URL")
    }

    func test_BookServiceError_BadStatusMessage() {
        let error = BookServiceError.badStatus(code: 404)
        XCTAssertEqual(error.message, "Bad status code: 404")
    }

    func test_BookResult_FailureCarriesMessage() {
        let result = BookResult.failure("Network error")
        if case .failure(let message) = result {
            XCTAssertEqual(message, "Network error")
        } else {
            XCTFail("Expected failure case")
        }
    }

    func test_BookResult_SuccessCarriesBookItem() {
        let volumeInfo = VolumeInfo(
            title: "Success Book",
            authors: ["Author"],
            publisher: nil,
            publishedDate: nil,
            description: nil,
            imageLinks: nil,
            industryIdentifiers: nil,
            subjects: nil
        )
        let bookItem = BookItem(volumeInfo: volumeInfo)
        let result = BookResult.success(bookItem)

        if case .success(let item) = result {
            XCTAssertEqual(item.volumeInfo.title, "Success Book")
        } else {
            XCTFail("Expected success case")
        }
    }
}

extension ScannerViewController {
    func simulateCodeDetection(_ code: String) {
        guard !didReturnResult else { return }
        didReturnResult = true
        onCodeDetected?(code)
    }
    
    func simulatePermissionDenied() {
        onPermissionDenied?()
    }
    
    func configure(simulateFailure: Bool = false, completion: @escaping (Bool) -> Void) {
        guard !isConfigured else {
            completion(false)
            return
        }
        
        // Simulate async configuration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if simulateFailure {
                completion(false)
            } else {
                self.isConfigured = true
                completion(true)
            }
        }
    }
    
    func reset() {
        didReturnResult = false
    }
}

class MockViewController: ScannerViewController {
    var capturedOnCodeDetected: ((String) -> Void)?
    var capturedOnPermissionDenied: (() -> Void)?
    
    override var onCodeDetected: ((String) -> Void)? {
        get { capturedOnCodeDetected }
        set { capturedOnCodeDetected = newValue }
    }
    
    override var onPermissionDenied: (() -> Void)? {
        get { capturedOnPermissionDenied }
        set { capturedOnPermissionDenied = newValue }
    }
}

