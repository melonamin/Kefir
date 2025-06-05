import Foundation
import SwiftKEF

/// Manages the playback state and track information
@MainActor
class PlaybackStateManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: SongInfo?
    @Published var trackPosition: Int64 = 0 // in milliseconds
    @Published var trackDuration: Int = 0 // in milliseconds
    
    /// Updates the playback state from a speaker event
    @MainActor
    func updateFromEvent(_ event: KEFSpeakerEvent) {
        if let playbackState = event.playbackState {
            isPlaying = playbackState == .playing
        }
        
        if let trackInfo = event.songInfo {
            currentTrack = trackInfo
        } else if isPlaying == false {
            currentTrack = nil
            trackPosition = 0
            trackDuration = 0
        }
        
        if let position = event.songPosition {
            trackPosition = position
        }
        
        if let duration = event.songDuration {
            trackDuration = duration
        }
        
        // Reset position/duration when not playing
        if !isPlaying {
            trackPosition = 0
            trackDuration = 0
        }
    }
    
    /// Resets all playback state
    func reset() {
        isPlaying = false
        currentTrack = nil
        trackPosition = 0
        trackDuration = 0
    }
    
    /// Updates track information from speaker
    func updateTrackInfo(from speaker: SpeakerConnectionManager) async {
        do {
            if isPlaying {
                currentTrack = try await speaker.getSongInformation()
                
                if let position = try await speaker.getSongPosition() {
                    trackPosition = position
                }
                
                if let duration = try await speaker.getSongDuration() {
                    trackDuration = duration
                }
            } else {
                reset()
            }
        } catch {
            // Silently fail - track info is not critical
        }
    }
}