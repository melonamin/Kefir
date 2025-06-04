import SwiftUI
import SwiftKEF

struct SourceButton: View {
    let source: KEFSource
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(source.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
    }
    
    private var sourceIcon: String {
        switch source {
        case .wifi: return "wifi"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        case .tv: return "tv"
        case .optic: return "fibrechannel"
        case .coaxial: return "cable.connector"
        case .analog: return "cable.connector.horizontal"
        case .usb: return "cable.connector"
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        SourceButton(source: .wifi, isSelected: true, action: {})
        SourceButton(source: .bluetooth, isSelected: false, action: {})
        SourceButton(source: .tv, isSelected: false, action: {})
    }
    .padding()
}