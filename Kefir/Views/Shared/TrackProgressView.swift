import SwiftUI

struct TrackProgressView: View {
    let position: Int64
    let duration: Int
    let onSeek: (Int64) -> Void
    
    // Note: KEF speakers don't support seeking, so this is display-only
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(position) / Double(duration)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color(NSColor.separatorColor).opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress fill
                    Capsule()
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                }
                // Add a subtle overlay to indicate non-interactive
                .allowsHitTesting(false) // Explicitly disable interaction
            }
            .frame(height: 12)
            
            // Time labels
            HStack {
                Text(formatTime(Int(position)))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Track Progress (Read-only)")
            .font(.headline)
        
        TrackProgressView(
            position: 90000, // 1:30
            duration: 240000, // 4:00
            onSeek: { _ in 
                print("Seeking not supported")
            }
        )
        
        TrackProgressView(
            position: 0,
            duration: 180000, // 3:00
            onSeek: { _ in }
        )
        
        TrackProgressView(
            position: 180000, // 3:00
            duration: 180000, // 3:00
            onSeek: { _ in }
        )
        
        Text("Note: KEF speakers don't support seeking")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 300)
}
