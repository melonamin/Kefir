import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SpeakersTab(appState: appState)
                .tabItem {
                    Label("Speakers", systemImage: "hifispeaker.2.fill")
                }
                .tag(0)
            
            ShortcutsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(1)
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
        .padding(20)
    }
}

// MARK: - Speakers Tab

struct SpeakersTab: View {
    @ObservedObject var appState: AppState
    @State private var selectedSpeaker: SpeakerProfile?
    @State private var showingAddSpeaker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Manage your KEF speakers")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Speaker List
            VStack(spacing: 0) {
                List(selection: $selectedSpeaker) {
                    ForEach(appState.speakers) { speaker in
                        SpeakerRow(speaker: speaker, isSelected: selectedSpeaker?.id == speaker.id)
                            .tag(speaker)
                    }
                }
                .listStyle(InsetListStyle())
                .frame(minHeight: 250)
                
                // Action Bar
                HStack(spacing: 8) {
                    Button(action: { showingAddSpeaker = true }) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        if let speaker = selectedSpeaker {
                            Task {
                                try? await appState.removeSpeaker(speaker)
                                selectedSpeaker = nil
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(selectedSpeaker == nil)
                    
                    Spacer()
                    
                    Button("Set as Default") {
                        if let speaker = selectedSpeaker {
                            Task {
                                try? await appState.setDefaultSpeaker(speaker)
                            }
                        }
                    }
                    .disabled(selectedSpeaker == nil || selectedSpeaker?.isDefault == true)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingAddSpeaker) {
            AddSpeakerView(appState: appState)
        }
    }
}

struct SpeakerRow: View {
    let speaker: SpeakerProfile
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(speaker.name)
                        .font(.system(size: 13))
                    
                    if speaker.isDefault {
                        Text("DEFAULT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(3)
                    }
                }
                
                Text(speaker.host)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if speaker.id == speaker.id { // Check if currently connected
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Shortcuts Tab

struct ShortcutsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure global keyboard shortcuts")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            GroupBox("Volume Control") {
                VStack(spacing: 12) {
                    ShortcutRow(label: "Volume Up", name: .volumeUp)
                    ShortcutRow(label: "Volume Down", name: .volumeDown)
                    ShortcutRow(label: "Toggle Mute", name: .toggleMute)
                }
                .padding(.vertical, 8)
            }
            
            GroupBox("Playback Control") {
                VStack(spacing: 12) {
                    ShortcutRow(label: "Play/Pause", name: .playPause)
                    ShortcutRow(label: "Next Track", name: .nextTrack)
                    ShortcutRow(label: "Previous Track", name: .previousTrack)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            Text("Press shortcuts while recording to set them")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct ShortcutRow: View {
    let label: String
    let name: KeyboardShortcuts.Name
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 120, alignment: .leading)
            
            KeyboardShortcuts.Recorder(for: name)
                .fixedSize()
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 0) {
            // App Icon and Version
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "hifispeaker.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("Kefir Menubar")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 40)
            
            // Description
            Text("Control your KEF wireless speakers from the macOS menu bar")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, 20)
            
            Spacer()
            
            // Links
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    Link(destination: URL(string: "https://github.com/yourusername/kef")!) {
                        Label("GitHub", systemImage: "link")
                            .font(.system(size: 13))
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/kef/issues")!) {
                        Label("Report Issue", systemImage: "exclamationmark.bubble")
                            .font(.system(size: 13))
                    }
                }
                
                Divider()
                    .frame(width: 200)
                
                Text("© 2024 Kefir Contributors")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}