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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Speaker")
                .font(.largeTitle)
                .bold()
            
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
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Test Connection") {
                    Task {
                        await testConnection()
                    }
                }
                .disabled(speakerName.isEmpty || speakerHost.isEmpty || isLoading)
                
                Button("Add") {
                    Task {
                        await addSpeaker()
                    }
                }
                .keyboardShortcut(.return)
                .disabled(speakerName.isEmpty || speakerHost.isEmpty || isLoading)
                .buttonStyle(.borderedProminent)
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
        }
        .padding(30)
        .frame(width: 400)
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