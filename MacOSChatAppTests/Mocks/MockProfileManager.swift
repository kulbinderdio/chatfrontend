import Foundation
@testable import MacOSChatApp

class MockProfileManager: ProfileManager {
    var mockProfiles: [ModelProfile] = []
    var profileChangedHandler: (() -> Void)?
    var lastUpdatedProfileId: String?
    
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
    
    override func getSelectedProfile() -> ModelProfile? {
        guard let selectedProfileId = selectedProfileId else {
            return nil
        }
        
        return mockProfiles.first { $0.id == selectedProfileId }
    }
    
    override func getAPIKey(for profileId: String) -> String? {
        return "mock-api-key"
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
        lastUpdatedProfileId = id
        
        // Update isDefault flag for all profiles
        for i in 0..<mockProfiles.count {
            mockProfiles[i].isDefault = (mockProfiles[i].id == id)
        }
        
        // Select this profile
        selectedProfileId = id
    }
}
