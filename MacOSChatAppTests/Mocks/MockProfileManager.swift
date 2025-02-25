import Foundation
@testable import MacOSChatApp

class MockProfileManager: ProfileManager {
    var mockProfiles: [ModelProfile] = []
    var profileChangedHandler: (() -> Void)?
    var lastUpdatedProfileId: String?
    var apiKeys: [String: String] = [:]
    
    override var selectedProfileId: String? {
        get { return _selectedProfileId }
        set { _selectedProfileId = newValue }
    }
    
    private var _selectedProfileId: String? = nil
    
    override var profiles: [ModelProfile] {
        get { return mockProfiles }
        set { mockProfiles = newValue }
    }
    
    func notifyProfileChanged() {
        profileChangedHandler?()
    }
    
    override func createProfile(name: String, apiEndpoint: URL, apiKey: String, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws -> ModelProfile {
        let profile = ModelProfile(
            id: UUID().uuidString,
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint.absoluteString,
            isDefault: isDefault,
            parameters: parameters
        )
        
        mockProfiles.append(profile)
        apiKeys[profile.id] = apiKey
        return profile
    }
    
    override func updateProfile(id: String, name: String, apiEndpoint: URL, apiKey: String?, modelName: String, parameters: ModelParameters, isDefault: Bool = false) throws {
        guard let index = mockProfiles.firstIndex(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        let updatedProfile = ModelProfile(
            id: id,
            name: name,
            modelName: modelName,
            apiEndpoint: apiEndpoint.absoluteString,
            isDefault: isDefault,
            parameters: parameters
        )
        
        mockProfiles[index] = updatedProfile
        if let apiKey = apiKey, !apiKey.isEmpty {
            apiKeys[id] = apiKey
        }
    }
    
    override func deleteProfile(id: String) throws {
        guard let index = mockProfiles.firstIndex(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        if mockProfiles.count <= 1 {
            throw ProfileError.cannotDeleteLastProfile
        }
        
        if id == selectedProfileId {
            throw ProfileError.cannotDeleteSelectedProfile
        }
        
        mockProfiles.remove(at: index)
        apiKeys.removeValue(forKey: id)
    }
    
    override func getSelectedProfile() -> ModelProfile? {
        guard let selectedProfileId = selectedProfileId else {
            return mockProfiles.first { $0.isDefault }
        }
        
        return mockProfiles.first { $0.id == selectedProfileId }
    }
    
    override func getAPIKey(for profileId: String) -> String? {
        return apiKeys[profileId] ?? "test-api-key"
    }
    
    func getProfileName(for profileId: String?) -> String {
        guard let profileId = profileId, let profile = mockProfiles.first(where: { $0.id == profileId }) else {
            return "Default"
        }
        return profile.name
    }
    
    func getModelName(for profileId: String?) -> String {
        guard let profileId = profileId, let profile = mockProfiles.first(where: { $0.id == profileId }) else {
            return "Unknown"
        }
        return profile.modelName
    }
    
    override func setDefaultProfile(id: String) throws {
        guard mockProfiles.contains(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        lastUpdatedProfileId = id
        
        // Update isDefault flag for all profiles
        for i in 0..<mockProfiles.count {
            mockProfiles[i].isDefault = (mockProfiles[i].id == id)
        }
        
        // Select this profile
        selectedProfileId = id
    }
    
    override func duplicateProfile(id: String) throws -> ModelProfile {
        guard let profile = mockProfiles.first(where: { $0.id == id }) else {
            throw ProfileError.notFound
        }
        
        let newProfile = ModelProfile(
            id: UUID().uuidString,
            name: "\(profile.name) (Copy)",
            modelName: profile.modelName,
            apiEndpoint: profile.apiEndpoint,
            isDefault: false,
            parameters: profile.parameters
        )
        
        mockProfiles.append(newProfile)
        apiKeys[newProfile.id] = apiKeys[id]
        return newProfile
    }
    
    override func selectProfile(id: String) {
        selectedProfileId = id
    }
}
