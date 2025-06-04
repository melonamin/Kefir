import SwiftUI
import SwiftKEF

struct BottomBar: View {
    @ObservedObject var appState: AppState
    @Binding var showingAddSpeaker: Bool
    @State private var showingPowerOffConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Speaker info and source selection
            if let speaker = appState.currentSpeaker, appState.isConnected && appState.powerStatus == .powerOn {
                // Main bottom bar
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
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
                        showingPowerOffConfirmation = true
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .confirmationDialog(
                        "Turn off speaker?",
                        isPresented: $showingPowerOffConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Turn Off", role: .destructive) {
                            Task { await appState.togglePower() }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will put \(speaker.name) into standby mode.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                // Simplified bottom bar when not connected or in standby
                HStack {
                    // Show different indicator based on connection status
                    if appState.isConnected {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
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
                            HStack(spacing: 6) {
                                Image(systemName: "hifispeaker.2.fill")
                                    .font(.system(size: 14))
                                Text("Speakers")
                                    .font(.system(size: 13))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary)
                        }
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
