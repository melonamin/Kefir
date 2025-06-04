import SwiftUI
import SwiftKEF

struct PopoverView: View {
    @ObservedObject var appState: AppState
    @State private var showingAddSpeaker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            if let speaker = appState.currentSpeaker {
                if appState.isConnected {
                    if appState.powerStatus == .powerOn {
                        ConnectedView(appState: appState, speaker: speaker)
                    } else {
                        StandbyView(appState: appState, speaker: speaker)
                    }
                } else {
                    DisconnectedView(appState: appState, speaker: speaker)
                }
            } else {
                EmptyStateView(showingAddSpeaker: $showingAddSpeaker)
            }
            
            // Bottom bar
            BottomBar(
                appState: appState,
                showingAddSpeaker: $showingAddSpeaker
            )
        }
        .frame(width: 360, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddSpeaker) {
            AddSpeakerView(appState: appState)
        }
    }
}

// MARK: - Connected View

struct ConnectedView: View {
    @ObservedObject var appState: AppState
    let speaker: SpeakerProfile
    @State private var isDraggingVolume = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Player Card - always show for streaming sources
                    if appState.currentSource == .wifi || appState.currentSource == .bluetooth {
                        NowPlayingCard(
                            track: appState.currentTrack,
                            isPlaying: appState.isPlaying,
                            volume: $appState.currentVolume,
                            isMuted: $appState.isMuted,
                            isDragging: $isDraggingVolume,
                            onPrevious: { Task { await appState.previousTrack() } },
                            onPlayPause: { Task { await appState.togglePlayPause() } },
                            onNext: { Task { await appState.nextTrack() } },
                            onVolumeChange: { newVolume in
                                Task { await appState.setVolume(newVolume) }
                            },
                            onMuteToggle: {
                                Task { await appState.toggleMute() }
                            },
                            onAdjust: { amount in
                                Task { await appState.adjustVolume(by: amount) }
                            }
                        )
                    } else {
                        // Show simple volume control for non-streaming sources
                        VolumeCard(
                            volume: $appState.currentVolume,
                            isMuted: $appState.isMuted,
                            isDragging: $isDraggingVolume,
                            onVolumeChange: { newVolume in
                                Task { await appState.setVolume(newVolume) }
                            },
                            onMuteToggle: {
                                Task { await appState.toggleMute() }
                            },
                            onAdjust: { amount in
                                Task { await appState.adjustVolume(by: amount) }
                            }
                        )
                    }
                }
                .padding(20)
            }
        }
    }
}

// MARK: - Components

struct SpeakerHeader: View {
    let name: String
    let isConnected: Bool
    let powerAction: () -> Void
    
    var body: some View {
        HStack {
            // Speaker info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isConnected ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "hifispeaker.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isConnected ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 18, weight: .semibold))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(isConnected ? "Connected" : "Disconnected")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Power button
            Button(action: powerAction) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "power")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct VolumeCard: View {
    @Binding var volume: Int
    @Binding var isMuted: Bool
    @Binding var isDragging: Bool
    let onVolumeChange: (Int) -> Void
    let onMuteToggle: () -> Void
    let onAdjust: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text("Volume")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Text("\(volume)%")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(isDragging ? .accentColor : .primary)
            }
            
            // Slider
            ModernSlider(
                value: Binding(
                    get: { Double(volume) },
                    set: { onVolumeChange(Int($0)) }
                ),
                isDragging: $isDragging
            )
            
            // Buttons
            HStack(spacing: 40) {
                ControlButton(
                    icon: "minus",
                    action: { onAdjust(-5) }
                )
                
                ControlButton(
                    icon: isMuted ? "speaker.slash.fill" : "speaker.fill",
                    isLarge: true,
                    isAccent: isMuted,
                    action: onMuteToggle
                )
                
                ControlButton(
                    icon: "plus",
                    action: { onAdjust(5) }
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SourceCard: View {
    let currentSource: KEFSource
    let onSourceChange: (KEFSource) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                Text("Input Source")
                    .font(.system(size: 15, weight: .medium))
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(KEFSource.allCases, id: \.self) { source in
                    SourceButton(
                        source: source,
                        isSelected: source == currentSource,
                        action: { onSourceChange(source) }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct NowPlayingCard: View {
    let track: SongInfo?
    let isPlaying: Bool
    @Binding var volume: Int
    @Binding var isMuted: Bool
    @Binding var isDragging: Bool
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onVolumeChange: (Int) -> Void
    let onMuteToggle: () -> Void
    let onAdjust: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Track info
            HStack(spacing: 16) {
                // Album art
                AlbumArtView(coverURL: track?.coverURL)
                    .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let track = track {
                        if let title = track.title {
                            Text(title)
                                .font(.system(size: 15, weight: .medium))
                                .lineLimit(1)
                        }
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        if let album = track.album {
                            Text(album)
                                .font(.system(size: 12))
                                .foregroundColor(Color.secondary.opacity(0.5))
                                .lineLimit(1)
                        }
                    } else {
                        Text("No track info")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Ready to play")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isPlaying {
                    SoundWaveAnimation()
                }
            }
            
            // Volume control
            VStack(spacing: 12) {
                HStack {
                    Text("\(volume)%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDragging ? .accentColor : .secondary)
                    Spacer()
                    Button(action: onMuteToggle) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isMuted ? .accentColor : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                ModernSlider(
                    value: Binding(
                        get: { Double(volume) },
                        set: { onVolumeChange(Int($0)) }
                    ),
                    isDragging: $isDragging
                )
            }
            
            // Playback controls
            HStack(spacing: 32) {
                PlayButton(icon: "backward.fill", size: .small, action: onPrevious)
                PlayButton(
                    icon: isPlaying ? "pause.fill" : "play.fill",
                    size: .large,
                    action: onPlayPause
                )
                PlayButton(icon: "forward.fill", size: .small, action: onNext)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Controls

struct ModernSlider: View {
    @Binding var value: Double
    @Binding var isDragging: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color(NSColor.separatorColor).opacity(0.3))
                    .frame(height: 6)
                
                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(value / 100), height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    )
                    .offset(x: geometry.size.width * CGFloat(value / 100) - 11)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let newValue = min(100, max(0, Double(drag.location.x / geometry.size.width) * 100))
                        value = newValue
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .frame(height: 22)
    }
}

struct ControlButton: View {
    let icon: String
    var isLarge: Bool = false
    var isAccent: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isAccent ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                    )
                    .frame(width: isLarge ? 50 : 40, height: isLarge ? 50 : 40)
                
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 22 : 16, weight: .medium))
                    .foregroundColor(isAccent ? .white : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SourceButton: View {
    let source: KEFSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(source.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sourceIcon: String {
        switch source {
        case .wifi: return "wifi"
        case .bluetooth: return "bluetooth"
        case .tv: return "tv"
        case .optic: return "optic.fill"
        case .coaxial: return "cable.connector"
        case .analog: return "cable.connector.horizontal"
        case .usb: return "cable.connector"
        }
    }
}

struct PlayButton: View {
    enum Size { case small, large }
    
    let icon: String
    let size: Size
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(size == .large ? Color.accentColor : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(size == .large ? Color.clear : Color(NSColor.separatorColor), lineWidth: 2)
                    )
                    .frame(width: size == .large ? 56 : 40, height: size == .large ? 56 : 40)
                
                Image(systemName: icon)
                    .font(.system(size: size == .large ? 22 : 16, weight: .medium))
                    .foregroundColor(size == .large ? .white : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SoundWaveAnimation: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: animating ? 24 : 12)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Bottom Bar

struct BottomBar: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddSpeaker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Speaker info and source selection
            if let speaker = appState.currentSpeaker, appState.isConnected && appState.powerStatus == .powerOn {
                HStack {
                    // Speaker info
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(speaker.name)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Spacer()
                    
                    // Source selector
                    Menu {
                        ForEach(KEFSource.allCases, id: \.self) { source in
                            Button(action: {
                                Task { await appState.setSource(source) }
                            }) {
                                HStack {
                                    Image(systemName: sourceIcon(for: source))
                                    Text(source.displayName)
                                    if source == appState.currentSource {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: sourceIcon(for: appState.currentSource))
                                .font(.system(size: 12))
                            Text(appState.currentSource.displayName)
                                .font(.system(size: 12))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.secondary)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    
                    // Power button
                    Button(action: {
                        Task { await appState.togglePower() }
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(NSColor.quaternarySystemFill))
            }
            
            // Main bottom bar
            HStack {
                // Speaker selector
                Menu {
                    ForEach(appState.speakers) { speaker in
                        Button(action: {
                            Task { await appState.selectSpeaker(speaker) }
                        }) {
                            HStack {
                                Text(speaker.name)
                                if speaker.isDefault {
                                    Text("(default)")
                                        .font(.caption)
                                }
                                if speaker.id == appState.currentSpeaker?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button("Add Speaker...") {
                        showingAddSpeaker = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hifispeaker.2.fill")
                            .font(.system(size: 14))
                        Text("Speakers")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                Spacer()
                
                // Settings button
                SettingsLink {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Quit button
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
    
    private func sourceIcon(for source: KEFSource) -> String {
        switch source {
        case .wifi: return "wifi"
        case .bluetooth: return "bluetooth"
        case .tv: return "tv"
        case .optic: return "optic.fill"
        case .coaxial: return "cable.connector"
        case .analog: return "cable.connector.horizontal"
        case .usb: return "cable.connector"
        }
    }
}

// MARK: - Empty States

struct DisconnectedView: View {
    @ObservedObject var appState: AppState
    let speaker: SpeakerProfile
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            // Text
            VStack(spacing: 8) {
                Text(speaker.name)
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Connection Failed")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("Check that the speaker is powered on and connected to the network")
                    .font(.system(size: 13))
                    .foregroundColor(Color.secondary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }
            
            // Retry button
            Button(action: {
                Task { await appState.selectSpeaker(speaker) }
            }) {
                Label("Retry Connection", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    @Binding var showingAddSpeaker: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color(NSColor.separatorColor).opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "hifispeaker.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            
            // Text
            VStack(spacing: 8) {
                Text("Welcome to Kefir")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Add a speaker to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Add button
            Button(action: { showingAddSpeaker = true }) {
                Label("Add Speaker", systemImage: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StandbyView: View {
    @ObservedObject var appState: AppState
    let speaker: SpeakerProfile
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "moon.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            
            // Text
            VStack(spacing: 8) {
                Text(speaker.name)
                    .font(.system(size: 20, weight: .semibold))
                
                Text("In Standby")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text("Speaker is connected but powered down")
                    .font(.system(size: 13))
                    .foregroundColor(Color.secondary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 250)
            }
            
            // Power on button
            Button(action: {
                Task { await appState.togglePower() }
            }) {
                Label("Power On", systemImage: "power")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Album Art View

struct AlbumArtView: View {
    let coverURL: String?
    @State private var albumImage: NSImage?
    @State private var isLoading = false
    @State private var currentURL: String?
    
    var body: some View {
        ZStack {
            if let image = albumImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .task(id: coverURL) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // Reset state if URL changes or is nil
        if coverURL != currentURL {
            albumImage = nil
            currentURL = coverURL
        }
        
        guard let urlString = coverURL,
              let url = URL(string: urlString) else {
            albumImage = nil
            isLoading = false
            return
        }
        
        // Don't reload if we already have the image for this URL
        if currentURL == urlString && albumImage != nil {
            return
        }
        
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let image = NSImage(data: data) {
                albumImage = image
                isLoading = false
            } else {
                albumImage = nil
                isLoading = false
            }
        } catch {
            albumImage = nil
            isLoading = false
        }
    }
}

// MARK: - Extensions

extension KEFSource {
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .bluetooth: return "Bluetooth"
        case .tv: return "TV"
        case .optic: return "Optical"
        case .coaxial: return "Coaxial"
        case .analog: return "Analog"
        case .usb: return "USB"
        }
    }
}