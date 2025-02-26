import Foundation
import Combine

class KeychainManager: ObservableObject {
    // UserDefaults keys for storage
    private enum UserDefaultsKey {
        static let apiKeyPrefix = "api_key_"
        static let profilePrefix = "profile_"
    }
    
    // Comprehensive cache to minimize UserDefaults access
    private static var cache: [String: Any] = [:]
    
    // UserDefaults for storage
    private let userDefaults = UserDefaults.standard
    
    // MARK: - API Key Methods
    
    func saveAPIKey(_ apiKey: String) {
        saveAPIKey(apiKey, forProfileId: nil)
    }
    
    func saveAPIKey(_ apiKey: String, forProfileId profileId: String? = nil) {
        let userDefaultsKey = profileId != nil ? "\(UserDefaultsKey.apiKeyPrefix)\(profileId!)" : "\(UserDefaultsKey.apiKeyPrefix)default"
        
        // Update cache first
        KeychainManager.cache[userDefaultsKey] = apiKey
        
        // Save to UserDefaults
        userDefaults.set(apiKey, forKey: userDefaultsKey)
        print("API key saved for profile: \(String(describing: profileId))")
    }
    
    func getAPIKey() -> String? {
        return getAPIKey(for: nil)
    }
    
    func getAPIKey(for profileId: String? = nil) -> String? {
        let userDefaultsKey = profileId != nil ? "\(UserDefaultsKey.apiKeyPrefix)\(profileId!)" : "\(UserDefaultsKey.apiKeyPrefix)default"
        
        // Check cache first
        if let cachedKey = KeychainManager.cache[userDefaultsKey] as? String {
            return cachedKey
        }
        
        // If not in cache, get from UserDefaults
        if let apiKey = userDefaults.string(forKey: userDefaultsKey) {
            // Store in cache for future use
            KeychainManager.cache[userDefaultsKey] = apiKey
            return apiKey
        }
        
        return nil
    }
    
    func deleteAPIKey() {
        deleteAPIKey(forProfileId: nil)
    }
    
    func deleteAPIKey(forProfileId profileId: String? = nil) {
        let userDefaultsKey = profileId != nil ? "\(UserDefaultsKey.apiKeyPrefix)\(profileId!)" : "\(UserDefaultsKey.apiKeyPrefix)default"
        
        // Remove from cache first
        KeychainManager.cache.removeValue(forKey: userDefaultsKey)
        
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: userDefaultsKey)
        print("API key deleted for profile: \(String(describing: profileId))")
    }
    
    // MARK: - Profile Methods
    
    func saveProfile(_ profile: ModelProfile) {
        let userDefaultsKey = UserDefaultsKey.profilePrefix + profile.id
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            
            // Store in cache
            KeychainManager.cache[userDefaultsKey] = data
            
            // Save to UserDefaults
            userDefaults.set(data, forKey: userDefaultsKey)
            print("Profile saved: \(profile.name)")
        } catch {
            print("Failed to encode profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(id: String) -> ModelProfile? {
        let userDefaultsKey = UserDefaultsKey.profilePrefix + id
        
        // Check cache first
        if let cachedData = KeychainManager.cache[userDefaultsKey] as? Data {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(ModelProfile.self, from: cachedData)
            } catch {
                print("Failed to decode cached profile: \(error.localizedDescription)")
            }
        }
        
        // If not in cache, get from UserDefaults
        if let data = userDefaults.data(forKey: userDefaultsKey) {
            do {
                // Store in cache for future use
                KeychainManager.cache[userDefaultsKey] = data
                
                let decoder = JSONDecoder()
                let profile = try decoder.decode(ModelProfile.self, from: data)
                return profile
            } catch {
                print("Failed to decode profile from UserDefaults: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
    func getAllProfiles() -> [ModelProfile] {
        // This is a placeholder implementation
        // In a real implementation, we would fetch all profiles from UserDefaults
        
        print("Fetching all profiles")
        return ModelProfile.defaultProfiles
    }
    
    func deleteProfile(id: String) {
        let userDefaultsKey = UserDefaultsKey.profilePrefix + id
        
        // Remove from cache first
        KeychainManager.cache.removeValue(forKey: userDefaultsKey)
        
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: userDefaultsKey)
        print("Profile deleted: \(id)")
    }
}
