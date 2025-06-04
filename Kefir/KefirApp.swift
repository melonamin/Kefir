import SwiftUI
import SwiftKEF
import AsyncHTTPClient
import KeyboardShortcuts

@main
struct KefirMenubarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState ?? AppState())
                .frame(width: 600, height: 500)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var appState: AppState!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
        
        // Create app state
        appState = AppState()
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hifispeaker.fill", accessibilityDescription: "Kefir")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: PopoverView(appState: appState))
        popover.behavior = .transient
        popover.animates = true
    }
    
    @MainActor @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Activate app to ensure popover gets focus
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var speakers: [SpeakerProfile] = []
    @Published var currentSpeaker: SpeakerProfile?
    @Published var isConnected = false
    @Published var currentVolume: Int = 0
    @Published var isMuted = false
    @Published var currentSource: KEFSource = .wifi
    @Published var isPlaying = false
    @Published var currentTrack: SongInfo?
    @Published var powerStatus: KEFSpeakerStatus = .standby
    
    private var speaker: KEFSpeaker?
    private var httpClient: HTTPClient?
    private var refreshTimer: Timer?
    private let config = ConfigurationManager()
    
    init() {
        Task {
            await loadConfiguration()
            await setupKeyboardShortcuts()
        }
    }
    
    func cleanup() async {
        refreshTimer?.invalidate()
        if let client = httpClient {
            try? await client.shutdown()
        }
    }
    
    func loadConfiguration() async {
        speakers = await config.getSpeakers()
        if let defaultSpeaker = await config.getDefaultSpeaker() {
            await selectSpeaker(defaultSpeaker)
        }
    }
    
    func selectSpeaker(_ profile: SpeakerProfile) async {
        currentSpeaker = profile
        
        // Clean up existing connection
        refreshTimer?.invalidate()
        if let client = httpClient {
            try? await client.shutdown()
        }
        
        // Create new connection
        httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        speaker = KEFSpeaker(host: profile.host, httpClient: httpClient!)
        
        // Initial status update
        await updateStatus()
        
        // Start refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task {
                await self.updateStatus()
            }
        }
    }
    
    func updateStatus() async {
        guard let speaker = speaker else { return }
        
        do {
            powerStatus = try await speaker.getStatus()
            isConnected = true // If we can get status, speaker is connected
            
            if powerStatus == .powerOn {
                currentVolume = try await speaker.getVolume()
                currentSource = try await speaker.getSource()
                isPlaying = try await speaker.isPlaying()
                
                if isPlaying {
                    currentTrack = try? await speaker.getSongInformation()
                } else {
                    currentTrack = nil
                }
            }
        } catch {
            isConnected = false
            print("Status update failed: \(error)")
        }
    }
    
    // MARK: - Speaker Control Methods
    
    func setVolume(_ volume: Int) async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.setVolume(volume)
            currentVolume = volume
        } catch {
            print("Failed to set volume: \(error)")
        }
    }
    
    func adjustVolume(by amount: Int) async {
        await setVolume(min(100, max(0, currentVolume + amount)))
    }
    
    func toggleMute() async {
        guard let speaker = speaker else { return }
        do {
            if isMuted {
                try await speaker.unmute()
            } else {
                try await speaker.mute()
            }
            isMuted.toggle()
        } catch {
            print("Failed to toggle mute: \(error)")
        }
    }
    
    func setSource(_ source: KEFSource) async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.setSource(source)
            currentSource = source
        } catch {
            print("Failed to set source: \(error)")
        }
    }
    
    func togglePlayPause() async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.togglePlayPause()
            isPlaying.toggle()
            await updateStatus()
        } catch {
            print("Failed to toggle playback: \(error)")
        }
    }
    
    func nextTrack() async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.nextTrack()
            await updateStatus()
        } catch {
            print("Failed to skip track: \(error)")
        }
    }
    
    func previousTrack() async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.previousTrack()
            await updateStatus()
        } catch {
            print("Failed to go to previous track: \(error)")
        }
    }
    
    func togglePower() async {
        guard let speaker = speaker else { return }
        do {
            if powerStatus == .powerOn {
                try await speaker.shutdown()
            } else {
                try await speaker.powerOn()
            }
            // Add a small delay before updating status to allow speaker to process the command
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await updateStatus()
        } catch {
            print("Failed to toggle power: \(error)")
        }
    }
    
    // MARK: - Speaker Profile Management
    
    func addSpeaker(name: String, host: String) async throws {
        _ = try await config.addSpeaker(name: name, host: host, setAsDefault: speakers.isEmpty)
        await loadConfiguration()
    }
    
    func removeSpeaker(_ profile: SpeakerProfile) async throws {
        try await config.removeSpeaker(id: profile.id)
        await loadConfiguration()
    }
    
    func setDefaultSpeaker(_ profile: SpeakerProfile) async throws {
        try await config.setDefaultSpeaker(id: profile.id)
        await loadConfiguration()
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func setupKeyboardShortcuts() async {
        KeyboardShortcuts.onKeyUp(for: .volumeUp) { [weak self] in
            Task { @MainActor in
                await self?.adjustVolume(by: 5)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .volumeDown) { [weak self] in
            Task { @MainActor in
                await self?.adjustVolume(by: -5)
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleMute) { [weak self] in
            Task { @MainActor in
                await self?.toggleMute()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .playPause) { [weak self] in
            Task { @MainActor in
                await self?.togglePlayPause()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .nextTrack) { [weak self] in
            Task { @MainActor in
                await self?.nextTrack()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .previousTrack) { [weak self] in
            Task { @MainActor in
                await self?.previousTrack()
            }
        }
    }
}

// MARK: - Keyboard Shortcut Names

extension KeyboardShortcuts.Name {
    static let volumeUp = Self("volumeUp")
    static let volumeDown = Self("volumeDown")
    static let toggleMute = Self("toggleMute")
    static let playPause = Self("playPause")
    static let nextTrack = Self("nextTrack")
    static let previousTrack = Self("previousTrack")
}
