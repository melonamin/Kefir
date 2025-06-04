import SwiftUI
import SwiftKEF

struct NowPlayingCard: View {
    let track: SongInfo?
    let isPlaying: Bool
    let trackPosition: Int64
    let trackDuration: Int
    @Binding var volume: Int
    @Binding var isMuted: Bool
    @Binding var isDragging: Bool
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onVolumeChange: (Int) -> Void
    let onMuteToggle: () -> Void
    let onAdjust: (Int) -> Void
    let onSeek: (Int64) -> Void
    
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
            
            // Progress indicator
            if trackDuration > 0 {
                TrackProgressView(
                    position: trackPosition,
                    duration: trackDuration,
                    onSeek: onSeek
                )
            } else {
                // Show placeholder when no duration info
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(NSColor.separatorColor).opacity(0.2))
                                .frame(height: 4)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("--:--")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                        Spacer()
                        Text("--:--")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
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
            // Volume control
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill" )
                    .font(.system(size: 14))
                
                ModernSlider(
                    value: Binding(
                        get: { Double(volume) },
                        set: { onVolumeChange(Int($0)) }
                    ),
                    isDragging: $isDragging
                )
                Button(action: onMuteToggle) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(isMuted ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    @State var volume = 50
    @State var isMuted = false
    @State var isDragging = false
    
    let sampleTrack = SongInfo(
        title: "Bohemian Rhapsody",
        artist: "Queen",
        album: "A Night at the Opera",
        coverURL: nil
    )
    
    return NowPlayingCard(
        track: sampleTrack,
        isPlaying: true,
        trackPosition: 90000, // 1:30
        trackDuration: 240000, // 4:00
        volume: $volume,
        isMuted: $isMuted,
        isDragging: $isDragging,
        onPrevious: {},
        onPlayPause: {},
        onNext: {},
        onVolumeChange: { _ in },
        onMuteToggle: {},
        onAdjust: { _ in },
        onSeek: { position in
            print("Seeking to: \(position)ms")
        }
    )
    .frame(width: 320)
    .padding()
}
