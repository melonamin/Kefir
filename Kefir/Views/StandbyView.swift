import SwiftUI

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

#Preview {
    let appState = AppState()
    let speaker = SpeakerProfile(
        name: "Living Room",
        host: "192.168.1.100",
        isDefault: true
    )
    
    return StandbyView(appState: appState, speaker: speaker)
        .frame(width: 360, height: 420)
}