//
//  Book_ScannerTests.swift
//  Book ScannerTests
//
//  Created by Israel Manzo on 2/21/26.
//

import XCTest
@testable import Book_Scanner

class Book_ScannerTests: XCTest  {
    
    var sut: ScannerViewController!

    override func setUp() {
        sut = ScannerViewController()
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
    
    override func tearDown() {
        sut = nil
    }

}

extension ScannerViewController {
    func simulateCodeDetection(_ code: String) {
        guard !didReturnResult else { return }
        didReturnResult = true
        onCodeDetected?(code)
    }
}
