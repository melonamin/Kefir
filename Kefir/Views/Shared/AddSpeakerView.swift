import SwiftUI
import SwiftKEF
import AsyncHTTPClient

struct AddSpeakerView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var speakerName = ""
    @State private var speakerHost = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Discovery states
    @State private var isDiscovering = true
    @State private var discoveryFailed = false
    @State private var discoveredSpeakers: [DiscoveredSpeaker] = []
    @State private var selectedDiscoveredSpeaker: DiscoveredSpeaker?
    @State private var showManualEntry = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Speaker")
                .font(.largeTitle)
                .bold()
            
            if isDiscovering {
                // Discovery in progress
                discoveryView
            } else if !discoveredSpeakers.isEmpty && !showManualEntry {
                // Show discovered speakers
                discoveredSpeakersView
            } else {
                // Manual entry (either no speakers found or user chose manual)
                manualEntryView
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
        }
        .padding(30)
        .frame(width: 450, height: 380)
        .task {
            // Start discovery automatically when view appears
            await discoverSpeakers()
        }
    }
    
    private var discoveryView: some View {
        VStack(spacing: 16) {
            
            // Animated network icon with wave effects
            ZStack {
                // Wave effect circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(index) * 50, height: 80 + CGFloat(index) * 50)
                        .scaleEffect(isDiscovering ? 1.2 : 0.8)
                        .opacity(isDiscovering ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                            value: isDiscovering
                        )
                }
                
                // Center pulsing circle
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isDiscovering ? 1.1 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: isDiscovering
                    )
                
                // Network icon with glow
                Image(systemName: "wifi")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
                    .scaleEffect(isDiscovering ? 1.0 : 0.9)
                    .shadow(color: .accentColor.opacity(0.6), radius: isDiscovering ? 20 : 10)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: isDiscovering
                    )
            }
            
            VStack(spacing: 4) {
                Text("Searching for KEF speakers...")
                    .font(.headline)
                    .opacity(isDiscovering ? 1.0 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isDiscovering
                    )
                
                Text("This may take up to 10 seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            
            Button("Enter Manually") {
                isDiscovering = false
                showManualEntry = true
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .focusable(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var discoveredSpeakersView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Found \(discoveredSpeakers.count) Speaker\(discoveredSpeakers.count == 1 ? "" : "s")")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Enter Manually") {
                        showManualEntry = true
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .focusable(false)
                }
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(discoveredSpeakers, id: \.host) { speaker in
                            DiscoveredSpeakerRow(
                                speaker: speaker,
                                isSelected: selectedDiscoveredSpeaker?.host == speaker.host,
                                action: {
                                    selectedDiscoveredSpeaker = speaker
                                    speakerName = speaker.name
                                    speakerHost = speaker.host
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(width: 350)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Refresh") {
                    Task {
                        isDiscovering = true
                        await discoverSpeakers()
                    }
                }
                .disabled(isDiscovering)
                
                Button("Add Selected") {
                    Task {
                        await addDiscoveredSpeaker()
                    }
                }
                .disabled(selectedDiscoveredSpeaker == nil || isLoading)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
    }
    
    private var manualEntryView: some View {
        VStack(spacing: 20) {
            if discoveryFailed && !showManualEntry {
                Text("No speakers found on the network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speaker Name")
                        .font(.headline)
                    TextField("e.g., Living Room", text: $speakerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP Address or Hostname")
                        .font(.headline)
                    TextField("e.g., 192.168.1.100", text: $speakerHost)
                        .textFieldStyle(.roundedBorder)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(width: 300)
            
            HStack(spacing: 12) {
                if !discoveredSpeakers.isEmpty && showManualEntry {
                    Button("Back to Discovered") {
                        showManualEntry = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                .focusable(false)
                
                Spacer()
                
                Button("Test Connection") {
                    Task {
                        await testConnection()
                    }
                }
                .disabled(speakerName.isEmpty || speakerHost.isEmpty || isLoading)
                .focusable(false)
                
                Button("Add") {
                    Task {
                        await addSpeaker()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(speakerName.isEmpty || speakerHost.isEmpty || isLoading)
                .buttonStyle(.borderedProminent)
                .focusable(false)
            }
        }
    }
    
    private func discoverSpeakers() async {
        isDiscovering = true
        discoveryFailed = false
        errorMessage = nil
        discoveredSpeakers = []
        selectedDiscoveredSpeaker = nil
        
        do {
            let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
            defer {
                Task {
                    try? await httpClient.shutdown()
                }
            }
            
            let speakers = try await KEFSpeaker.discover(
                httpClient: httpClient,
                timeout: 10.0
            )
            
            discoveredSpeakers = speakers
            
            if speakers.isEmpty {
                discoveryFailed = true
            } else if speakers.count == 1 {
                // Auto-select if only one speaker found
                selectedDiscoveredSpeaker = speakers.first
                speakerName = speakers.first?.name ?? ""
                speakerHost = speakers.first?.host ?? ""
            }
        } catch {
            discoveryFailed = true
            errorMessage = "Discovery failed: \(error.localizedDescription)"
        }
        
        isDiscovering = false
    }
    
    private func addDiscoveredSpeaker() async {
        guard let speaker = selectedDiscoveredSpeaker else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Test connection first
            let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
            let kefSpeaker = KEFSpeaker(host: speaker.host, httpClient: httpClient)
            
            _ = try await kefSpeaker.getStatus()
            try await httpClient.shutdown()
            
            // Add to configuration
            try await appState.addSpeaker(name: speaker.name, host: speaker.host)
            
            // Select the new speaker
            if let newSpeaker = appState.speakers.first(where: { $0.name == speaker.name }) {
                await appState.selectSpeaker(newSpeaker)
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to add speaker: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func testConnection() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
            let speaker = KEFSpeaker(host: speakerHost, httpClient: httpClient)
            
            _ = try await speaker.getStatus()
            errorMessage = nil
            
            try await httpClient.shutdown()
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func addSpeaker() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Test connection first
            let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
            let speaker = KEFSpeaker(host: speakerHost, httpClient: httpClient)
            
            _ = try await speaker.getStatus()
            try await httpClient.shutdown()
            
            // Add to configuration
            try await appState.addSpeaker(name: speakerName, host: speakerHost)
            
            // Select the new speaker
            if let newSpeaker = appState.speakers.first(where: { $0.name == speakerName }) {
                await appState.selectSpeaker(newSpeaker)
            }
            
            dismiss()
        } catch {
            errorMessage = "Failed to add speaker: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// Row view for discovered speakers
struct DiscoveredSpeakerRow: View {
    let speaker: DiscoveredSpeaker
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(speaker.name)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Text(speaker.host)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let model = speaker.model {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(model)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
