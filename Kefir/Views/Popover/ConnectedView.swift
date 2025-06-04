import SwiftUI
import SwiftKEF

struct ConnectedView: View {
    @ObservedObject var appState: AppState
    let speaker: SpeakerProfile
    @State private var isDraggingVolume = false
    
    var body: some View {
        // Player Card - always show for streaming sources
        if appState.currentSource == .wifi || appState.currentSource == .bluetooth {
            NowPlayingCard(
                track: appState.currentTrack,
                isPlaying: appState.isPlaying,
                trackPosition: appState.trackPosition,
                trackDuration: appState.trackDuration,
                volume: Binding(
                    get: { appState.currentVolume },
                    set: { _ in }
                ),
                isMuted: Binding(
                    get: { appState.isMuted },
                    set: { _ in }
                ),
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
                },
                onSeek: { position in
                    Task { await appState.seekToPosition(position) }
                }
            )
        } else {
            // Show simple volume control for non-streaming sources
            VolumeCard(
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
                },
                onAdjust: { amount in
                    Task { await appState.adjustVolume(by: amount) }
                }
            )
        }
    }
}

#Preview {
    ConnectedView(
        appState: AppState(),
        speaker: SpeakerProfile(
            name: "Living Room",
            host: "192.168.1.100",
            isDefault: true
        )
    )
}
