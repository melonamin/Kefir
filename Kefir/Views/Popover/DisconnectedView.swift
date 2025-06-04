import SwiftUI

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
            .focusable(false)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let appState = AppState()
    let speaker = SpeakerProfile(
        name: "Living Room",
        host: "192.168.1.100",
        isDefault: true
    )
    
    return DisconnectedView(appState: appState, speaker: speaker)
        .frame(width: 360, height: 420)
}