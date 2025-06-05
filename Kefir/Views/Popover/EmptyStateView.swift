import SwiftUI

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
            .focusable(false)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
