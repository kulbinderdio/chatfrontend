import Foundation
import KeychainAccess
import Combine

class KeychainManager: ObservableObject {
    // Single shared keychain instance
    private static let sharedKeychain = Keychain(service: "com.yourcompany.MacOSChatApp")
        .accessibility(.afterFirstUnlock)
    
    // Keys
    private enum KeychainKey {
        static let apiKey = "api_key"
        static let profilePrefix = "profile_"
    }
    
    // Comprehensive cache to minimize keychain access
    private static var cache: [String: Any] = [:]
    
    // MARK: - API Key Methods
    
    func saveAPIKey(_ apiKey: String) {
        saveAPIKey(apiKey, forProfileId: nil)
    }
    
    func saveAPIKey(_ apiKey: String, forProfileId profileId: String? = nil) {
        let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
        
        // Update cache first
        KeychainManager.cache[key] = apiKey
        
        // Then update keychain in background
        DispatchQueue.global(qos: .background).async {
            do {
                try KeychainManager.sharedKeychain.set(apiKey, key: key)
                print("API key saved to keychain for profile: \(String(describing: profileId))")
            } catch {
                print("Failed to save API key for profile: \(error.localizedDescription)")
            }
        }
    }
    
    func getAPIKey() -> String? {
        return getAPIKey(for: nil)
    }
    
    func getAPIKey(for profileId: String? = nil) -> String? {
        let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
        
        // Check cache first
        if let cachedKey = KeychainManager.cache[key] as? String {
            return cachedKey
        }
        
        // If not in cache, get from keychain
        do {
            if let apiKey = try KeychainManager.sharedKeychain.get(key) {
                // Store in cache for future use
                KeychainManager.cache[key] = apiKey
                return apiKey
            }
            return nil
        } catch {
            print("Failed to retrieve API key for profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteAPIKey() {
        deleteAPIKey(forProfileId: nil)
    }
    
    func deleteAPIKey(forProfileId profileId: String? = nil) {
        let key = profileId != nil ? "\(KeychainKey.apiKey)_\(profileId!)" : KeychainKey.apiKey
        
        // Remove from cache first
        KeychainManager.cache.removeValue(forKey: key)
        
        // Then remove from keychain in background
        DispatchQueue.global(qos: .background).async {
            do {
                try KeychainManager.sharedKeychain.remove(key)
                print("API key deleted from keychain for profile: \(String(describing: profileId))")
            } catch {
                print("Failed to delete API key for profile: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Profile Methods
    
    func saveProfile(_ profile: ModelProfile) {
        let key = KeychainKey.profilePrefix + profile.id
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            
            // Store in cache
            KeychainManager.cache[key] = data
            
            // Then update keychain in background
            DispatchQueue.global(qos: .background).async {
                do {
                    try KeychainManager.sharedKeychain.set(data, key: key)
                    print("Profile saved to keychain: \(profile.name)")
                } catch {
                    print("Failed to save profile: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to encode profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(id: String) -> ModelProfile? {
        let key = KeychainKey.profilePrefix + id
        
        // Check cache first
        if let cachedData = KeychainManager.cache[key] as? Data {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(ModelProfile.self, from: cachedData)
            } catch {
                print("Failed to decode cached profile: \(error.localizedDescription)")
            }
        }
        
        // If not in cache, get from keychain
        do {
            guard let data = try KeychainManager.sharedKeychain.getData(key) else {
                return nil
            }
            
            // Store in cache
            KeychainManager.cache[key] = data
            
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
        let key = KeychainKey.profilePrefix + id
        
        // Remove from cache first
        KeychainManager.cache.removeValue(forKey: key)
        
        // Then remove from keychain in background
        DispatchQueue.global(qos: .background).async {
            do {
                try KeychainManager.sharedKeychain.remove(key)
                print("Profile deleted from keychain: \(id)")
            } catch {
                print("Failed to delete profile: \(error.localizedDescription)")
            }
        }
    }
}
