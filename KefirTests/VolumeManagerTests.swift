import XCTest
@testable import Kefir
import SwiftKEF

@MainActor
final class VolumeManagerTests: XCTestCase {
    
    func testInitialState() {
        let manager = VolumeManager()
        
        XCTAssertEqual(manager.currentVolume, 0)
        XCTAssertFalse(manager.isMuted)
    }
    
    func testUpdateFromEvent() {
        let manager = VolumeManager()
        
        // Create a mock event with volume and mute state
        let event = KEFSpeakerEvent(
            source: nil,
            volume: 75,
            songInfo: nil,
            songPosition: nil,
            songDuration: nil,
            playbackState: nil,
            speakerStatus: nil,
            deviceName: nil,
            isMuted: true
        )
        
        manager.updateFromEvent(event)
        
        XCTAssertEqual(manager.currentVolume, 75)
        XCTAssertTrue(manager.isMuted)
    }
    
    func testVolumeClampingMin() async throws {
        let manager = VolumeManager()
        let mockConnection = MockSpeakerConnectionManager()
        
        // Test setting volume below minimum
        try await manager.setVolume(-10, using: mockConnection)
        
        XCTAssertEqual(manager.currentVolume, 0)
        XCTAssertEqual(mockConnection.lastSetVolume, 0)
    }
    
    func testVolumeClampingMax() async throws {
        let manager = VolumeManager()
        let mockConnection = MockSpeakerConnectionManager()
        
        // Test setting volume above maximum
        try await manager.setVolume(150, using: mockConnection)
        
        XCTAssertEqual(manager.currentVolume, 100)
        XCTAssertEqual(mockConnection.lastSetVolume, 100)
    }
    
    func testAdjustVolume() async throws {
        let manager = VolumeManager()
        let mockConnection = MockSpeakerConnectionManager()
        
        // Set initial volume
        manager.currentVolume = 50
        
        // Increase volume
        try await manager.adjustVolume(by: 20, using: mockConnection)
        XCTAssertEqual(manager.currentVolume, 70)
        
        // Decrease volume
        try await manager.adjustVolume(by: -30, using: mockConnection)
        XCTAssertEqual(manager.currentVolume, 40)
    }
    
    func testVolumeStepOperations() async throws {
        let manager = VolumeManager()
        let mockConnection = MockSpeakerConnectionManager()
        
        // Set initial volume
        manager.currentVolume = 50
        
        // Increase by step
        try await manager.increaseVolume(using: mockConnection)
        XCTAssertEqual(manager.currentVolume, 55)
        
        // Decrease by step
        try await manager.decreaseVolume(using: mockConnection)
        XCTAssertEqual(manager.currentVolume, 50)
    }
    
    func testToggleMute() async throws {
        let manager = VolumeManager()
        let mockConnection = MockSpeakerConnectionManager()
        
        // Initial state - not muted
        XCTAssertFalse(manager.isMuted)
        
        // Toggle to mute
        try await manager.toggleMute(using: mockConnection)
        XCTAssertTrue(manager.isMuted)
        XCTAssertTrue(mockConnection.muteWasCalled)
        
        // Toggle to unmute
        try await manager.toggleMute(using: mockConnection)
        XCTAssertFalse(manager.isMuted)
        XCTAssertTrue(mockConnection.unmuteWasCalled)
    }
    
    func testReset() {
        let manager = VolumeManager()
        
        // Set some values
        manager.currentVolume = 75
        manager.isMuted = true
        
        // Reset
        manager.reset()
        
        XCTAssertEqual(manager.currentVolume, 0)
        XCTAssertFalse(manager.isMuted)
    }
}

// MARK: - Mock Classes

@MainActor
class MockSpeakerConnectionManager: SpeakerConnectionManager {
    var lastSetVolume: Int?
    var muteWasCalled = false
    var unmuteWasCalled = false
    
    override func setVolume(_ volume: Int) async throws {
        lastSetVolume = volume
    }
    
    override func mute() async throws {
        muteWasCalled = true
    }
    
    override func unmute() async throws {
        unmuteWasCalled = true
    }
    
    override func getVolume() async throws -> Int {
        return lastSetVolume ?? 0
    }
}