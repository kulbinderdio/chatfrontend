import Foundation
import KeychainAccess
import Combine

class KeychainManager: ObservableObject {
    private let keychain: Keychain
    
    // Keys
    private enum KeychainKey {
        static let apiKey = "api_key"
        static let profilePrefix = "profile_"
    }
    
    init() {
        self.keychain = Keychain(service: "com.yourcompany.MacOSChatApp")
    }
    
    // MARK: - API Key Methods
    
    func saveAPIKey(_ apiKey: String) {
        do {
            try keychain.set(apiKey, key: KeychainKey.apiKey)
            print("API key saved to keychain")
        } catch {
            print("Failed to save API key: \(error.localizedDescription)")
        }
    }
    
    func saveAPIKey(_ apiKey: String, forProfileId profileId: String? = nil) {
        do {
            let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
            try keychain.set(apiKey, key: key)
            print("API key saved to keychain for profile: \(String(describing: profileId))")
        } catch {
            print("Failed to save API key for profile: \(error.localizedDescription)")
        }
    }
    
    func getAPIKey() -> String? {
        do {
            let apiKey = try keychain.get(KeychainKey.apiKey)
            return apiKey
        } catch {
            print("Failed to retrieve API key: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getAPIKey(for profileId: String? = nil) -> String? {
        do {
            let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
            let apiKey = try keychain.get(key)
            return apiKey
        } catch {
            print("Failed to retrieve API key for profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteAPIKey() {
        do {
            try keychain.remove(KeychainKey.apiKey)
            print("API key deleted from keychain")
        } catch {
            print("Failed to delete API key: \(error.localizedDescription)")
        }
    }
    
    func deleteAPIKey(forProfileId profileId: String? = nil) {
        do {
            let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
            try keychain.remove(key)
            print("API key deleted from keychain for profile: \(String(describing: profileId))")
        } catch {
            print("Failed to delete API key for profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Methods
    
    func saveProfile(_ profile: ModelProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            
            let key = KeychainKey.profilePrefix + profile.id
            try keychain.set(data, key: key)
            print("Profile saved to keychain: \(profile.name)")
        } catch {
            print("Failed to save profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(id: String) -> ModelProfile? {
        do {
            let key = KeychainKey.profilePrefix + id
            guard let data = try keychain.getData(key) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let profile = try decoder.decode(ModelProfile.self, from: data)
            return profile
        } catch {
            print("Failed to retrieve profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getAllProfiles() -> [ModelProfile] {
        // This is a placeholder implementation
        // In a real implementation, we would fetch all profiles from the keychain
        
        print("Fetching all profiles")
        return ModelProfile.defaultProfiles
    }
    
    func deleteProfile(id: String) {
        do {
            let key = KeychainKey.profilePrefix + id
            try keychain.remove(key)
            print("Profile deleted from keychain: \(id)")
        } catch {
            print("Failed to delete profile: \(error.localizedDescription)")
        }
    }
}
