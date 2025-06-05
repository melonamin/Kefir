import SwiftUI
import SwiftKEF

struct MiniPlayerView: View {
    @ObservedObject var appState: AppState
    @State private var isDraggingVolume = false
    @State private var isHovering = false
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Background with visual effect
            VisualEffectBackground()
            
            // Content
            if appState.isConnected && appState.powerStatus == .powerOn {
                ZStack {
                    // Default view - Track info
                    HStack(spacing: 12) {
                        // Album art or speaker icon
                        ZStack {
                            if let coverURL = appState.currentTrack?.coverURL {
                                AlbumArtView(coverURL: coverURL)
                                    .frame(width: 50, height: 50)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "hifispeaker.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.accentColor)
                                    )
                            }
                        }
                        
                        // Track info
                        VStack(alignment: .leading, spacing: 4) {
                            if let track = appState.currentTrack, let title = track.title {
                                Text(title)
                                    .font(.system(size: 13, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                if let artist = track.artist {
                                    Text(artist)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            } else {
                                Text(appState.currentSpeaker?.name ?? "KEF Speaker")
                                    .font(.system(size: 13, weight: .medium))
                                Text(appState.source.displayName(for: appState.currentSource))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .opacity(isHovering ? 0 : 1)
                    
                    // Hover view - Controls
                    if isHovering {
                        HStack(spacing: 20) {
                            // Playback controls
                            if appState.currentSource == .wifi || appState.currentSource == .bluetooth {
                                HStack(spacing: 16) {
                                    Button(action: {
                                        Task { await appState.previousTrack() }
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .focusable(false)
                                    
                                    Button(action: {
                                        Task { await appState.togglePlayPause() }
                                    }) {
                                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .focusable(false)
                                    
                                    Button(action: {
                                        Task { await appState.nextTrack() }
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .focusable(false)
                                }
                                
                                Divider()
                                    .frame(height: 30)
                            }
                            
                            // Volume controls
                            MiniVolumeControl(
                                volume: Binding(
                                    get: { appState.currentVolume },
                                    set: { _ in }
                                ),
                                isMuted: Binding(
                                    get: { appState.isMuted },
                                    set: { _ in }
                                ),
                                isDragging: $isDraggingVolume,
                                onVolumeChange: { newVolume in
                                    Task { await appState.setVolume(newVolume) }
                                },
                                onMuteToggle: {
                                    Task { await appState.toggleMute() }
                                }
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(12)
            } else {
                // Disconnected or standby state
                HStack {
                    Image(systemName: "hifispeaker.slash")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text(appState.currentSpeaker?.name ?? "No Speaker")
                            .font(.system(size: 13, weight: .medium))
                        Text(appState.isConnected ? "Standby" : "Disconnected")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if appState.isConnected {
                        Button(action: {
                            Task { await appState.togglePower() }
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                    }
                }
                .padding(12)
            }
            
            // Close button (visible on hover)
            if isHovering {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                    }
                    Spacer()
                }
                .padding(6)
                .transition(.opacity)
            }
        }
        .frame(width: 280, height: 74)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

// Mini volume control for the floating player
struct MiniVolumeControl: View {
    @Binding var volume: Int
    @Binding var isMuted: Bool
    @Binding var isDragging: Bool
    let onVolumeChange: (Int) -> Void
    let onMuteToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            // Mute button
            Button(action: onMuteToggle) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isMuted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .focusable(false)
            
            // Volume up/down buttons
            Button(action: {
                let newVolume = max(0, volume - 5)
                onVolumeChange(newVolume)
            }) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .focusable(false)
            
            Text("\(volume)%")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40)
            
            Button(action: {
                let newVolume = min(100, volume + 5)
                onVolumeChange(newVolume)
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .focusable(false)
        }
    }
}

// Visual effect background
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    MiniPlayerView(appState: {
        let state = AppState()
        state.isConnected = true
        state.powerStatus = .powerOn
        state.volume.currentVolume = 50
        state.playback.isPlaying = true
        state.playback.currentTrack = SongInfo(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera"
        )
        return state
    }(), onClose: {})
    .frame(width: 280, height: 74)
}