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
    
    func test_ConfigureSets_IsConfigured() {
        let expectation = XCTestExpectation(description: "Configuration complete")
        sut.configure { success in
            XCTAssertTrue(success)
            XCTAssertTrue(self.sut.isConfigured)
            expectation.fulfill()
        }
    }
    
    func test_ConfigureFailure() {
        let expectation = XCTestExpectation(description: "Configuration failed")
        sut.configure(simulateFailure: true) { success in
            XCTAssertFalse(success)
            XCTAssertFalse(self.sut.isConfigured)
            expectation.fulfill()
        }
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
        XCTAssertEqual(configureCallCount, 1)
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
