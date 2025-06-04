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
    var miniPlayerWindowController: MiniPlayerWindowController?
    
    func applicationWillTerminate(_ notification: Notification) {
        Task {
            await appState?.cleanup()
        }
    }
    
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
        popover.contentViewController = NSHostingController(rootView: PopoverView(appState: appState, appDelegate: self))
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
    
    func showMiniPlayer() {
        print("showMiniPlayer called")
        DispatchQueue.main.async { [weak self] in
            if self?.miniPlayerWindowController == nil {
                print("Creating new mini player")
                self?.miniPlayerWindowController = MiniPlayerWindowController(appState: self?.appState ?? AppState())
            }
            self?.miniPlayerWindowController?.window?.makeKeyAndOrderFront(nil)
            self?.miniPlayerWindowController?.window?.orderFrontRegardless()
            print("Mini player window visible: \(self?.miniPlayerWindowController?.window?.isVisible ?? false)")
        }
    }
    
    func hideMiniPlayer() {
        DispatchQueue.main.async { [weak self] in
            self?.miniPlayerWindowController?.window?.close()
            self?.miniPlayerWindowController = nil
        }
    }
    
    func toggleMiniPlayer() {
        print("toggleMiniPlayer called")
        if miniPlayerWindowController?.window?.isVisible ?? false {
            print("Hiding mini player")
            hideMiniPlayer()
        } else {
            print("Showing mini player")
            showMiniPlayer()
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
    @Published var trackPosition: Int64 = 0 // in milliseconds
    @Published var trackDuration: Int = 0 // in milliseconds
    
    private var speaker: KEFSpeaker?
    private var httpClient: HTTPClient?
    private var pollingTask: Task<Void, Never>?
    private let config = ConfigurationManager()
    
    init() {
        Task {
            await loadConfiguration()
            await setupKeyboardShortcuts()
        }
    }
    
    deinit {
        pollingTask?.cancel()
    }
    
    func cleanup() async {
        pollingTask?.cancel()
        // Wait a bit for the task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        speaker = nil
        
        if let client = httpClient {
            try? await client.shutdown()
            httpClient = nil
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
        await cleanup()
        
        // Create new connection
        httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        speaker = KEFSpeaker(host: profile.host, httpClient: httpClient!)
        
        // Initial status update
        await updateStatus()
        
        // Only start polling if connected successfully
        if isConnected {
            startPolling()
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
                    // Try to get position and duration
                    if let position = try? await speaker.getSongPosition() {
                        trackPosition = position
                    }
                    if let duration = try? await speaker.getSongDuration() {
                        trackDuration = duration
                    }
                } else {
                    currentTrack = nil
                    trackPosition = 0
                    trackDuration = 0
                }
            }
        } catch {
            isConnected = false
            print("Status update failed: \(error)")
            
            // If it's a connection error, try to reconnect after a delay
            if !Task.isCancelled {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    if currentSpeaker != nil && !isConnected {
                        await updateStatus()
                    }
                }
            }
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
        } catch {
            print("Failed to toggle playback: \(error)")
        }
    }
    
    func nextTrack() async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.nextTrack()
        } catch {
            print("Failed to skip track: \(error)")
        }
    }
    
    func previousTrack() async {
        guard let speaker = speaker else { return }
        do {
            try await speaker.previousTrack()
        } catch {
            print("Failed to go to previous track: \(error)")
        }
    }
    
    func seekToPosition(_ position: Int64) async {
        // Note: KEF speakers don't support seeking through their API
        // This method exists for interface consistency but doesn't actually seek
        print("Seeking not supported by KEF speakers")
    }
    
    private func startPolling() {
        pollingTask?.cancel()
        
        guard let speaker = speaker else { return }
        
        pollingTask = Task {
            let eventStream = await speaker.startPolling(
                pollInterval: 10,
                pollSongStatus: true
            )
            
            do {
                for try await event in eventStream {
                    if Task.isCancelled { break }
                    
                    // Update state based on event
                    if let status = event.speakerStatus {
                        powerStatus = status
                        isConnected = true
                    }
                    
                    if powerStatus == .powerOn {
                        if let volume = event.volume {
                            currentVolume = volume
                        }
                        
                        if let source = event.source {
                            currentSource = source
                        }
                        
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
                        
                        if let muted = event.isMuted {
                            isMuted = muted
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
                }
            } catch {
                if !Task.isCancelled {
                    isConnected = false
                    print("Polling error: \(error)")
                }
            }
        }
    }
    
    func togglePower() async {
        guard let speaker = speaker else { return }
        do {
            if powerStatus == .powerOn {
                try await speaker.shutdown()
                powerStatus = .standby
            } else {
                try await speaker.powerOn()
                powerStatus = .powerOn
                // Re-start polling after power on
                startPolling()
            }
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
        // If removing current speaker, clean up connection first
        if currentSpeaker?.id == profile.id {
            await cleanup()
            currentSpeaker = nil
            isConnected = false
        }
        
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
        
        KeyboardShortcuts.onKeyUp(for: .toggleMiniPlayer) {
            Task { @MainActor in
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.toggleMiniPlayer()
                }
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
    static let toggleMiniPlayer = Self("toggleMiniPlayer")
}
