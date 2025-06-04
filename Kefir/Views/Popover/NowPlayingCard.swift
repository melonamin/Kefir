import SwiftUI
import SwiftKEF

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

//#Preview {
//    @State var volume = 50
//    @State var isMuted = false
//    @State var isDragging = false
//    
//    let sampleTrack = SongInfo(
//        title: "Sample Song",
//        artist: "Sample Artist",
//        album: "Sample Album",
//        albumArtist: nil,
//        year: nil,
//        duration: 240,
//        playerState: nil,
//        position: nil,
//        resolution: nil,
//        source: nil,
//        radio: nil,
//        radioStation: nil,
//        sampleRate: nil,
//        codec: nil,
//        playbackType: nil,
//        coverURL: nil
//    )
//    
//    NowPlayingCard(
//        track: sampleTrack,
//        isPlaying: true,
//        volume: $volume,
//        isMuted: $isMuted,
//        isDragging: $isDragging,
//        onPrevious: { },
//        onPlayPause: { },
//        onNext: { },
//        onVolumeChange: { _ in },
//        onMuteToggle: { },
//        onAdjust: { _ in }
//    )
//    .frame(width: 360)
//}
