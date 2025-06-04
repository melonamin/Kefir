import XCTest
@testable import Kefir
import SwiftKEF

@MainActor
final class ErrorManagerTests: XCTestCase {
    
    func testInitialState() {
        let manager = ErrorManager()
        
        XCTAssertNil(manager.currentError)
        XCTAssertFalse(manager.showingError)
    }
    
    func testShowGenericError() {
        let manager = ErrorManager()
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [
            NSLocalizedDescriptionKey: "Test error message"
        ])
        
        manager.showError(error)
        
        XCTAssertNotNil(manager.currentError)
        XCTAssertEqual(manager.currentError?.title, "Error")
        XCTAssertEqual(manager.currentError?.message, "Test error message")
        XCTAssertTrue(manager.currentError?.isRecoverable ?? false)
        XCTAssertTrue(manager.showingError)
    }
    
    func testShowSpeakerError() {
        let manager = ErrorManager()
        let error = SpeakerError.notConnected
        
        manager.showError(error, title: "Custom Title")
        
        XCTAssertNotNil(manager.currentError)
        XCTAssertEqual(manager.currentError?.title, "Custom Title")
        XCTAssertEqual(manager.currentError?.message, "No speaker connected")
        XCTAssertTrue(manager.showingError)
    }
    
    func testShowConfigurationError() {
        let manager = ErrorManager()
        let error = ConfigurationError.speakerAlreadyExists(name: "Living Room")
        
        manager.showError(error)
        
        XCTAssertNotNil(manager.currentError)
        XCTAssertEqual(manager.currentError?.message, "A speaker named 'Living Room' already exists")
    }
    
    func testShowConnectionError() {
        let manager = ErrorManager()
        let error = SpeakerError.connectionFailed("Network timeout")
        
        manager.showConnectionError(error)
        
        XCTAssertNotNil(manager.currentError)
        XCTAssertEqual(manager.currentError?.title, "Connection Failed")
        XCTAssertEqual(manager.currentError?.message, "Connection failed: Network timeout")
        XCTAssertTrue(manager.currentError?.isRecoverable ?? false)
    }
    
    func testShowOperationError() {
        let manager = ErrorManager()
        let error = SpeakerError.operationFailed("Volume change failed")
        
        manager.showOperationError(error, operation: "Set Volume")
        
        XCTAssertNotNil(manager.currentError)
        XCTAssertEqual(manager.currentError?.title, "Set Volume Failed")
        XCTAssertEqual(manager.currentError?.message, "Operation failed: Volume change failed")
    }
    
    func testDismissError() {
        let manager = ErrorManager()
        
        // Show an error
        manager.showError(SpeakerError.notConnected)
        XCTAssertTrue(manager.showingError)
        XCTAssertNotNil(manager.currentError)
        
        // Dismiss it
        manager.dismissError()
        
        XCTAssertFalse(manager.showingError)
        XCTAssertNil(manager.currentError)
    }
    
    func testPerformOperationSuccess() async {
        let manager = ErrorManager()
        
        let result = await manager.performOperation(operation: "Test Operation") {
            return 42
        }
        
        XCTAssertEqual(result, 42)
        XCTAssertFalse(manager.showingError)
    }
    
    func testPerformOperationFailure() async {
        let manager = ErrorManager()
        
        let result: Int? = await manager.performOperation(operation: "Test Operation") {
            throw SpeakerError.notConnected
        }
        
        XCTAssertNil(result)
        XCTAssertTrue(manager.showingError)
        XCTAssertEqual(manager.currentError?.title, "Test Operation Failed")
    }
    
    func testUserErrorIdentifiable() {
        let error1 = ErrorManager.UserError(
            title: "Test 1",
            message: "Message 1",
            isRecoverable: true
        )
        
        let error2 = ErrorManager.UserError(
            title: "Test 2",
            message: "Message 2",
            isRecoverable: false
        )
        
        XCTAssertNotEqual(error1.id, error2.id)
    }
}