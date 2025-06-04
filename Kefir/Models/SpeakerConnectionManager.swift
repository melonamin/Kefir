import Foundation
import SwiftKEF
import AsyncHTTPClient

/// Manages the connection and communication with a KEF speaker
@MainActor
class SpeakerConnectionManager: ObservableObject {
    @Published var isConnected = false
    @Published var powerStatus: KEFSpeakerStatus = .standby
    
    private var speaker: KEFSpeaker?
    private var httpClient: HTTPClient?
    private var pollingTask: Task<Void, Never>?
    
    deinit {
        pollingTask?.cancel()
    }
    
    /// Connects to a speaker with the given profile
    func connect(to profile: SpeakerProfile) async throws {
        // Clean up existing connection
        await disconnect()
        
        // Create new connection
        httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        speaker = KEFSpeaker(host: profile.host, httpClient: httpClient!)
        
        // Test connection
        do {
            powerStatus = try await speaker!.getStatus()
            isConnected = true
        } catch {
            isConnected = false
            throw error
        }
    }
    
    /// Disconnects from the current speaker
    func disconnect() async {
        pollingTask?.cancel()
        // Wait a bit for the task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        speaker = nil
        
        if let client = httpClient {
            try? await client.shutdown()
            httpClient = nil
        }
        
        isConnected = false
    }
    
    /// Starts polling the speaker for status updates
    func startPolling(pollInterval: Int = 10, pollSongStatus: Bool = true) async -> AsyncThrowingStream<KEFSpeakerEvent, Error>? {
        guard let speaker = speaker else { return nil }
        
        pollingTask?.cancel()
        
        let stream = await speaker.startPolling(
            pollInterval: pollInterval,
            pollSongStatus: pollSongStatus
        )
        
        return stream
    }
    
    /// Stops polling the speaker
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    // MARK: - Speaker Control Methods
    
    func getStatus() async throws -> KEFSpeakerStatus {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getStatus()
    }
    
    func setVolume(_ volume: Int) async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.setVolume(volume)
    }
    
    func getVolume() async throws -> Int {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getVolume()
    }
    
    func mute() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.mute()
    }
    
    func unmute() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.unmute()
    }
    
    func setSource(_ source: KEFSource) async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.setSource(source)
    }
    
    func getSource() async throws -> KEFSource {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getSource()
    }
    
    func togglePlayPause() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.togglePlayPause()
    }
    
    func nextTrack() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.nextTrack()
    }
    
    func previousTrack() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.previousTrack()
    }
    
    func powerOn() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.powerOn()
    }
    
    func shutdown() async throws {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        try await speaker.shutdown()
    }
    
    func isPlaying() async throws -> Bool {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.isPlaying()
    }
    
    func getSongInformation() async throws -> SongInfo? {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getSongInformation()
    }
    
    func getSongPosition() async throws -> Int64? {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getSongPosition()
    }
    
    func getSongDuration() async throws -> Int? {
        guard let speaker = speaker else { throw SpeakerError.notConnected }
        return try await speaker.getSongDuration()
    }
}

/// Errors specific to speaker operations
enum SpeakerError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "No speaker connected"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}