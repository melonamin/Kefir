import SwiftUI

struct TrackProgressView: View {
    let position: Int64
    let duration: Int
    let isPlaying: Bool
    let onSeek: (Int64) -> Void
    
    @State private var displayPosition: Int64 = 0
    @State private var lastUpdateTime = Date()
    @State private var timer: Timer?
    
    // Note: KEF speakers don't support seeking, so this is display-only
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(displayPosition) / Double(duration)
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
                        .animation(.linear(duration: 0.1), value: progress)
                }
                // Add a subtle overlay to indicate non-interactive
                .allowsHitTesting(false) // Explicitly disable interaction
            }
            .frame(height: 12)
            
            // Time labels
            HStack {
                Text(formatTime(Int(displayPosition)))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            displayPosition = position
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: position) { oldValue, newValue in
            // Update display position when we get a new position from the speaker
            displayPosition = newValue
            lastUpdateTime = Date()
        }
        .onChange(of: isPlaying) { oldValue, newValue in
            // Reset timer when play state changes
            if newValue {
                lastUpdateTime = Date()
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Only update if playing and not at the end
            if isPlaying && displayPosition < Int64(duration) {
                // Calculate elapsed time since last update
                let elapsed = Date().timeIntervalSince(lastUpdateTime)
                // Add elapsed time in milliseconds
                displayPosition = min(displayPosition + Int64(elapsed * 1000), Int64(duration))
                lastUpdateTime = Date()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
            isPlaying: true,
            onSeek: { _ in 
                print("Seeking not supported")
            }
        )
        
        TrackProgressView(
            position: 0,
            duration: 180000, // 3:00
            isPlaying: false,
            onSeek: { _ in }
        )
        
        TrackProgressView(
            position: 180000, // 3:00
            duration: 180000, // 3:00
            isPlaying: false,
            onSeek: { _ in }
        )
        
        Text("Note: KEF speakers don't support seeking")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 300)
}
