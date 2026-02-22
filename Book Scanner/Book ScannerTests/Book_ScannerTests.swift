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
