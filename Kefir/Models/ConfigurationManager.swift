import Foundation

// MARK: - Data Models

struct SpeakerProfile: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let host: String
    let lastSeen: Date
    let isDefault: Bool
    
    init(id: UUID = UUID(), name: String, host: String, lastSeen: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.lastSeen = lastSeen
        self.isDefault = isDefault
    }
}

struct Configuration: Codable {
    var speakers: [SpeakerProfile]
    var theme: Theme
    
    init(speakers: [SpeakerProfile] = [], theme: Theme = Theme()) {
        self.speakers = speakers
        self.theme = theme
    }
}

struct Theme: Codable {
    let useColors: Bool
    let useEmojis: Bool
    
    init(useColors: Bool = true, useEmojis: Bool = true) {
        self.useColors = useColors
        self.useEmojis = useEmojis
    }
}

// MARK: - Configuration Manager

actor ConfigurationManager {
    private let configDirectory: URL
    private let configFile: URL
    private var configuration: Configuration
    
    init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        self.configDirectory = homeDirectory.appendingPathComponent(".config/kefir")
        self.configFile = configDirectory.appendingPathComponent("config.json")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        
        // Load or create configuration
        if FileManager.default.fileExists(atPath: configFile.path),
           let data = try? Data(contentsOf: configFile) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let config = try? decoder.decode(Configuration.self, from: data) {
                self.configuration = config
            } else {
                self.configuration = Configuration()
            }
        } else {
            self.configuration = Configuration()
        }
    }
    
    private func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(configuration)
        try data.write(to: configFile)
    }
    
    // MARK: - Speaker Management
    
    func getSpeakers() -> [SpeakerProfile] {
        return configuration.speakers
    }
    
    func getSpeaker(byName name: String) -> SpeakerProfile? {
        return configuration.speakers.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getSpeaker(byId id: UUID) -> SpeakerProfile? {
        return configuration.speakers.first { $0.id == id }
    }
    
    func getDefaultSpeaker() -> SpeakerProfile? {
        return configuration.speakers.first { $0.isDefault }
    }
    
    @discardableResult
    func addSpeaker(name: String, host: String, setAsDefault: Bool = false) throws -> SpeakerProfile {
        // Check if speaker with same name exists
        if configuration.speakers.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            throw ConfigurationError.speakerAlreadyExists(name: name)
        }
        
        // If setting as default, clear other defaults
        if setAsDefault {
            configuration.speakers = configuration.speakers.map { speaker in
                SpeakerProfile(
                    id: speaker.id,
                    name: speaker.name,
                    host: speaker.host,
                    lastSeen: speaker.lastSeen,
                    isDefault: false
                )
            }
        }
        
        let newSpeaker = SpeakerProfile(
            name: name,
            host: host,
            isDefault: setAsDefault || configuration.speakers.isEmpty
        )
        
        configuration.speakers.append(newSpeaker)
        try save()
        
        return newSpeaker
    }
    
    func updateSpeaker(id: UUID, name: String? = nil, host: String? = nil) throws {
        guard let index = configuration.speakers.firstIndex(where: { $0.id == id }) else {
            throw ConfigurationError.speakerNotFound
        }
        
        let speaker = configuration.speakers[index]
        configuration.speakers[index] = SpeakerProfile(
            id: speaker.id,
            name: name ?? speaker.name,
            host: host ?? speaker.host,
            lastSeen: Date(),
            isDefault: speaker.isDefault
        )
        
        try save()
    }
    
    func removeSpeaker(id: UUID) throws {
        guard let index = configuration.speakers.firstIndex(where: { $0.id == id }) else {
            throw ConfigurationError.speakerNotFound
        }
        
        let wasDefault = configuration.speakers[index].isDefault
        configuration.speakers.remove(at: index)
        
        // If removed speaker was default, set first speaker as default
        if wasDefault && !configuration.speakers.isEmpty {
            configuration.speakers[0] = SpeakerProfile(
                id: configuration.speakers[0].id,
                name: configuration.speakers[0].name,
                host: configuration.speakers[0].host,
                lastSeen: configuration.speakers[0].lastSeen,
                isDefault: true
            )
        }
        
        try save()
    }
    
    func setDefaultSpeaker(id: UUID) throws {
        guard configuration.speakers.contains(where: { $0.id == id }) else {
            throw ConfigurationError.speakerNotFound
        }
        
        configuration.speakers = configuration.speakers.map { speaker in
            SpeakerProfile(
                id: speaker.id,
                name: speaker.name,
                host: speaker.host,
                lastSeen: speaker.lastSeen,
                isDefault: speaker.id == id
            )
        }
        
        try save()
    }
    
    func updateLastUsed(speakerId: UUID) throws {
        guard let index = configuration.speakers.firstIndex(where: { $0.id == speakerId }) else {
            throw ConfigurationError.speakerNotFound
        }
        
        let speaker = configuration.speakers[index]
        configuration.speakers[index] = SpeakerProfile(
            id: speaker.id,
            name: speaker.name,
            host: speaker.host,
            lastSeen: Date(),
            isDefault: speaker.isDefault
        )
        
        try save()
    }
    
    // MARK: - Theme Management
    
    func getTheme() -> Theme {
        return configuration.theme
    }
    
    func updateTheme(useColors: Bool? = nil, useEmojis: Bool? = nil) throws {
        configuration.theme = Theme(
            useColors: useColors ?? configuration.theme.useColors,
            useEmojis: useEmojis ?? configuration.theme.useEmojis
        )
        
        try save()
    }
}

// MARK: - Errors

enum ConfigurationError: LocalizedError {
    case speakerNotFound
    case speakerAlreadyExists(name: String)
    
    var errorDescription: String? {
        switch self {
        case .speakerNotFound:
            return NSLocalizedString("Speaker not found in configuration", comment: "Error when speaker is not found")
        case .speakerAlreadyExists(let name):
            return String(format: NSLocalizedString("A speaker named '%@' already exists", comment: "Error when speaker name already exists"), name)
        }
    }
}