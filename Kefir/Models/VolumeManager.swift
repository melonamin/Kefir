import Foundation
import SwiftKEF

/// Manages volume and mute state
@MainActor
class VolumeManager: ObservableObject {
    @Published var currentVolume: Int = 0
    @Published var isMuted = false
    
    private let minVolume = 0
    private let maxVolume = 100
    private let volumeStep = 5
    
    /// Updates volume from a speaker event
    func updateFromEvent(_ event: KEFSpeakerEvent) {
        if let volume = event.volume {
            currentVolume = volume
        }
        
        if let muted = event.isMuted {
            isMuted = muted
        }
    }
    
    /// Sets the volume to a specific value
    func setVolume(_ volume: Int, using speaker: SpeakerConnectionManager) async throws {
        let clampedVolume = min(maxVolume, max(minVolume, volume))
        try await speaker.setVolume(clampedVolume)
        currentVolume = clampedVolume
    }
    
    /// Adjusts volume by a specific amount
    func adjustVolume(by amount: Int, using speaker: SpeakerConnectionManager) async throws {
        try await setVolume(currentVolume + amount, using: speaker)
    }
    
    /// Increases volume by default step
    func increaseVolume(using speaker: SpeakerConnectionManager) async throws {
        try await adjustVolume(by: volumeStep, using: speaker)
    }
    
    /// Decreases volume by default step
    func decreaseVolume(using speaker: SpeakerConnectionManager) async throws {
        try await adjustVolume(by: -volumeStep, using: speaker)
    }
    
    /// Toggles mute state
    func toggleMute(using speaker: SpeakerConnectionManager) async throws {
        if isMuted {
            try await speaker.unmute()
        } else {
            try await speaker.mute()
        }
        isMuted.toggle()
    }
    
    /// Resets volume state
    func reset() {
        currentVolume = 0
        isMuted = false
    }
    
    /// Updates volume and mute state from speaker
    func updateFromSpeaker(using speaker: SpeakerConnectionManager) async throws {
        currentVolume = try await speaker.getVolume()
        // Note: KEF API doesn't have a getMuteStatus method, so mute state
        // is only updated through events or when toggling
    }
}