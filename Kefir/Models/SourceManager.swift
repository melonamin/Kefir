import Foundation
import SwiftKEF

/// Manages the current input source
@MainActor
class SourceManager: ObservableObject {
    @Published var currentSource: KEFSource = .wifi
    
    /// Available sources for KEF speakers
    static let availableSources: [KEFSource] = [
        .wifi,
        .bluetooth,
        .tv,
        .optic,
        .coaxial,
        .analog,
        .usb
    ]
    
    /// Updates source from a speaker event
    func updateFromEvent(_ event: KEFSpeakerEvent) {
        if let source = event.source {
            currentSource = source
        }
    }
    
    /// Sets the input source
    func setSource(_ source: KEFSource, using speaker: SpeakerConnectionManager) async throws {
        try await speaker.setSource(source)
        currentSource = source
    }
    
    /// Updates source from speaker
    func updateFromSpeaker(using speaker: SpeakerConnectionManager) async throws {
        currentSource = try await speaker.getSource()
    }
    
    /// Gets a user-friendly name for a source
    func displayName(for source: KEFSource) -> String {
        switch source {
        case .wifi: return "Wi-Fi"
        case .bluetooth: return "Bluetooth"
        case .tv: return "TV/ARC"
        case .optic: return "Optical"
        case .coaxial: return "Coaxial"
        case .analog: return "Analog"
        case .usb: return "USB"
        }
    }
    
    /// Gets an SF Symbol name for a source
    func symbolName(for source: KEFSource) -> String {
        switch source {
        case .wifi: return "wifi"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .tv: return "tv"
        case .optic: return "fibrechannel"
        case .coaxial: return "cable.connector"
        case .analog: return "cable.connector.horizontal"
        case .usb: return "cable.connector"
        }
    }
}