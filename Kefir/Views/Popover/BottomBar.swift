import SwiftUI
import SwiftKEF

struct BottomBar: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddSpeaker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Speaker info and source selection
            if let speaker = appState.currentSpeaker, appState.isConnected && appState.powerStatus == .powerOn {
                // Main bottom bar
                HStack {
                    // Speaker selector
                    Menu {
                        ForEach(appState.speakers) { speaker in
                            Button(action: {
                                Task { await appState.selectSpeaker(speaker) }
                            }) {
                                HStack {
                                    Text(speaker.name)
                                    if speaker.isDefault {
                                        Text("(default)")
                                            .font(.caption)
                                    }
                                    if speaker.id == appState.currentSpeaker?.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button("Add Speaker...") {
                            showingAddSpeaker = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "hifispeaker.2.fill")
                                .font(.system(size: 14))
                            Text(speaker.name)
                                .font(.system(size: 13))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    
                    Menu {
                        ForEach(KEFSource.allCases, id: \.self) { source in
                            Button(action: {
                                Task { await appState.setSource(source) }
                            }) {
                                HStack {
                                    Image(systemName: sourceIcon(for: source))
                                    Text(source.displayName)
                                    if source == appState.currentSource {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: sourceIcon(for: appState.currentSource))
                                .font(.system(size: 12))
                            Text(appState.currentSource.displayName)
                                .font(.system(size: 12))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(.secondary)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    Spacer()
                    
                    // Settings button
                    SettingsLink {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Power button
                    Button(action: {
                        Task { await appState.togglePower() }
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
    }
    
    private func sourceIcon(for source: KEFSource) -> String {
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
    @State var showingAddSpeaker = false
    let appState = AppState()
    
    return BottomBar(
        appState: appState,
        showingAddSpeaker: $showingAddSpeaker
    )
    .frame(width: 360)
}
