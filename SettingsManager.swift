import Foundation

struct GameSettings: Codable {
    var highScore: Int = 0
    var musicEnabled: Bool = true
    var isFullscreen: Bool = false
}

class SettingsManager {
    static let shared = SettingsManager()
    
    private let settingsURL: URL
    
    private init() {
        // Get config directory: ~/.config/tetrix.json
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configDir = homeDir.appendingPathComponent(".config", isDirectory: true)
        settingsURL = configDir.appendingPathComponent("tetrix.json")
    }
    
    func loadSettings() -> GameSettings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            return GameSettings()
        }
        
        do {
            let data = try Data(contentsOf: settingsURL)
            let decoder = JSONDecoder()
            let settings = try decoder.decode(GameSettings.self, from: data)
            return settings
        } catch {
            print("Failed to load settings: \(error)")
            return GameSettings()
        }
    }
    
    func saveSettings(_ settings: GameSettings) {
        do {
            // Ensure .config directory exists
            let configDir = settingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true, attributes: nil)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}
