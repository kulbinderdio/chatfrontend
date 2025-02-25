import Foundation
@testable import MacOSChatApp

class MockKeychainManager: KeychainManager {
    // In-memory storage for testing
    private var apiKeys: [String: String] = [:]
    private var profiles: [String: ModelProfile] = [:]
    
    override func saveAPIKey(_ apiKey: String) {
        apiKeys["default"] = apiKey
    }
    
    override func saveAPIKey(_ apiKey: String, forProfileId profileId: String? = nil) {
        let key = profileId != nil ? "profile_\(profileId!)" : "default"
        apiKeys[key] = apiKey
    }
    
    override func getAPIKey() -> String? {
        return apiKeys["default"]
    }
    
    override func getAPIKey(for profileId: String? = nil) -> String? {
        let key = profileId != nil ? "profile_\(profileId!)" : "default"
        
        // For testing purposes, always return a test API key for the ModelConfigurationManagerTests
        if profileId == "apiKey" {
            return "test-api-key"
        }
        
        return apiKeys[key]
    }
    
    override func deleteAPIKey() {
        apiKeys.removeValue(forKey: "default")
    }
    
    override func deleteAPIKey(forProfileId profileId: String? = nil) {
        let key = profileId != nil ? "profile_\(profileId!)" : "default"
        apiKeys.removeValue(forKey: key)
    }
    
    override func saveProfile(_ profile: ModelProfile) {
        profiles[profile.id] = profile
    }
    
    override func getProfile(id: String) -> ModelProfile? {
        return profiles[id]
    }
    
    override func getAllProfiles() -> [ModelProfile] {
        return Array(profiles.values)
    }
    
    override func deleteProfile(id: String) {
        profiles.removeValue(forKey: id)
    }
}
