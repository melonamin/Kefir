import XCTest
@testable import Kefir
import SwiftKEF

@MainActor
final class SourceManagerTests: XCTestCase {
    
    func testInitialState() {
        let manager = SourceManager()
        XCTAssertEqual(manager.currentSource, .wifi)
    }
    
    func testAvailableSources() {
        let expected: [KEFSource] = [.wifi, .bluetooth, .tv, .optical, .coaxial, .analog, .usb]
        XCTAssertEqual(SourceManager.availableSources, expected)
    }
    
    func testUpdateFromEvent() {
        let manager = SourceManager()
        
        let event = KEFSpeakerEvent(
            source: .bluetooth,
            volume: nil,
            songInfo: nil,
            songPosition: nil,
            songDuration: nil,
            playbackState: nil,
            speakerStatus: nil,
            deviceName: nil,
            isMuted: nil
        )
        
        manager.updateFromEvent(event)
        
        XCTAssertEqual(manager.currentSource, .bluetooth)
    }
    
    func testSetSource() async throws {
        let manager = SourceManager()
        let mockConnection = MockSpeakerConnectionForSource()
        
        try await manager.setSource(.optical, using: mockConnection)
        
        XCTAssertEqual(manager.currentSource, .optical)
        XCTAssertEqual(mockConnection.lastSetSource, .optical)
    }
    
    func testUpdateFromSpeaker() async throws {
        let manager = SourceManager()
        let mockConnection = MockSpeakerConnectionForSource()
        
        mockConnection.currentSource = .tv
        
        try await manager.updateFromSpeaker(using: mockConnection)
        
        XCTAssertEqual(manager.currentSource, .tv)
    }
    
    func testDisplayNames() {
        let manager = SourceManager()
        
        XCTAssertEqual(manager.displayName(for: .standby), "Standby")
        XCTAssertEqual(manager.displayName(for: .wifi), "Wi-Fi")
        XCTAssertEqual(manager.displayName(for: .bluetooth), "Bluetooth")
        XCTAssertEqual(manager.displayName(for: .tv), "TV/ARC")
        XCTAssertEqual(manager.displayName(for: .optical), "Optical")
        XCTAssertEqual(manager.displayName(for: .coaxial), "Coaxial")
        XCTAssertEqual(manager.displayName(for: .analog), "Analog")
        XCTAssertEqual(manager.displayName(for: .usb), "USB")
    }
    
    func testSymbolNames() {
        let manager = SourceManager()
        
        XCTAssertEqual(manager.symbolName(for: .standby), "power")
        XCTAssertEqual(manager.symbolName(for: .wifi), "wifi")
        XCTAssertEqual(manager.symbolName(for: .bluetooth), "bluetooth")
        XCTAssertEqual(manager.symbolName(for: .tv), "tv")
        XCTAssertEqual(manager.symbolName(for: .optical), "fibrechannel")
        XCTAssertEqual(manager.symbolName(for: .coaxial), "cable.coaxial")
        XCTAssertEqual(manager.symbolName(for: .analog), "cable.connector")
        XCTAssertEqual(manager.symbolName(for: .usb), "usb.port")
    }
}

// MARK: - Mock Classes

@MainActor
class MockSpeakerConnectionForSource: SpeakerConnectionManager {
    var currentSource: KEFSource = .wifi
    var lastSetSource: KEFSource?
    
    override func setSource(_ source: KEFSource) async throws {
        lastSetSource = source
        currentSource = source
    }
    
    override func getSource() async throws -> KEFSource {
        return currentSource
    }
}