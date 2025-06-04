import SwiftUI
import SwiftKEF

struct PopoverView: View {
    @ObservedObject var appState: AppState
    let appDelegate: AppDelegate
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
            
            BottomBar(
                appState: appState,
                appDelegate: appDelegate,
                showingAddSpeaker: $showingAddSpeaker
            )
        }
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingAddSpeaker) {
            AddSpeakerView(appState: appState)
        }
    }
}
