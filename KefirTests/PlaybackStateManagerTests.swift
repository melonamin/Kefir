import XCTest
@testable import Kefir
import SwiftKEF

@MainActor
final class PlaybackStateManagerTests: XCTestCase {
    
    func testInitialState() {
        let manager = PlaybackStateManager()
        
        XCTAssertFalse(manager.isPlaying)
        XCTAssertNil(manager.currentTrack)
        XCTAssertEqual(manager.trackPosition, 0)
        XCTAssertEqual(manager.trackDuration, 0)
    }
    
    func testUpdateFromEventPlaying() {
        let manager = PlaybackStateManager()
        
        let songInfo = SongInfo(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album"
        )
        
        let event = KEFSpeakerEvent(
            source: nil,
            volume: nil,
            songInfo: songInfo,
            songPosition: 30000, // 30 seconds
            songDuration: 180000, // 3 minutes
            playbackState: .playing,
            speakerStatus: nil,
            deviceName: nil,
            isMuted: nil
        )
        
        manager.updateFromEvent(event)
        
        XCTAssertTrue(manager.isPlaying)
        XCTAssertEqual(manager.currentTrack?.title, "Test Song")
        XCTAssertEqual(manager.trackPosition, 30000)
        XCTAssertEqual(manager.trackDuration, 180000)
    }
    
    func testUpdateFromEventPaused() {
        let manager = PlaybackStateManager()
        
        // First set playing state
        manager.isPlaying = true
        manager.currentTrack = SongInfo(title: "Test", artist: nil, album: nil)
        manager.trackPosition = 1000
        manager.trackDuration = 5000
        
        // Update with paused event
        let event = KEFSpeakerEvent(
            source: nil,
            volume: nil,
            songInfo: nil,
            songPosition: nil,
            songDuration: nil,
            playbackState: .paused,
            speakerStatus: nil,
            deviceName: nil,
            isMuted: nil
        )
        
        manager.updateFromEvent(event)
        
        XCTAssertFalse(manager.isPlaying)
        // When not playing, position and duration should reset
        XCTAssertEqual(manager.trackPosition, 0)
        XCTAssertEqual(manager.trackDuration, 0)
    }
    
    func testUpdateFromEventClearsTrackWhenNotPlaying() {
        let manager = PlaybackStateManager()
        
        // Set initial playing state
        manager.isPlaying = true
        manager.currentTrack = SongInfo(title: "Test", artist: nil, album: nil)
        
        // Event that sets playing to false without track info
        let event = KEFSpeakerEvent(
            source: nil,
            volume: nil,
            songInfo: nil,
            songPosition: nil,
            songDuration: nil,
            playbackState: .paused,
            speakerStatus: nil,
            deviceName: nil,
            isMuted: nil
        )
        
        manager.updateFromEvent(event)
        
        XCTAssertNil(manager.currentTrack)
    }
    
    func testReset() {
        let manager = PlaybackStateManager()
        
        // Set some values
        manager.isPlaying = true
        manager.currentTrack = SongInfo(title: "Test", artist: nil, album: nil)
        manager.trackPosition = 1000
        manager.trackDuration = 5000
        
        // Reset
        manager.reset()
        
        XCTAssertFalse(manager.isPlaying)
        XCTAssertNil(manager.currentTrack)
        XCTAssertEqual(manager.trackPosition, 0)
        XCTAssertEqual(manager.trackDuration, 0)
    }
    
    func testUpdateTrackInfoWhilePlaying() async {
        let manager = PlaybackStateManager()
        let mockConnection = MockSpeakerConnectionForPlayback()
        
        // Set playing state
        manager.isPlaying = true
        
        // Set mock data
        mockConnection.songInfo = SongInfo(title: "New Song", artist: "New Artist", album: nil)
        mockConnection.songPosition = 45000
        mockConnection.songDuration = 240000
        
        await manager.updateTrackInfo(from: mockConnection)
        
        XCTAssertEqual(manager.currentTrack?.title, "New Song")
        XCTAssertEqual(manager.trackPosition, 45000)
        XCTAssertEqual(manager.trackDuration, 240000)
    }
    
    func testUpdateTrackInfoWhileNotPlaying() async {
        let manager = PlaybackStateManager()
        let mockConnection = MockSpeakerConnectionForPlayback()
        
        // Not playing
        manager.isPlaying = false
        
        // Set mock data (shouldn't be used)
        mockConnection.songInfo = SongInfo(title: "Should Not Appear", artist: nil, album: nil)
        mockConnection.songPosition = 1000
        mockConnection.songDuration = 5000
        
        await manager.updateTrackInfo(from: mockConnection)
        
        // Should be reset since not playing
        XCTAssertNil(manager.currentTrack)
        XCTAssertEqual(manager.trackPosition, 0)
        XCTAssertEqual(manager.trackDuration, 0)
    }
}

// MARK: - Mock Classes

@MainActor
class MockSpeakerConnectionForPlayback: SpeakerConnectionManager {
    var songInfo: SongInfo?
    var songPosition: Int64?
    var songDuration: Int?
    
    override func getSongInformation() async throws -> SongInfo? {
        return songInfo
    }
    
    override func getSongPosition() async throws -> Int64? {
        return songPosition
    }
    
    override func getSongDuration() async throws -> Int? {
        return songDuration
    }
}