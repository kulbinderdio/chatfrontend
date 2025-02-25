import XCTest
@testable import MacOSChatApp

class ProfileManagerTests: XCTestCase {
    var profileManager: ProfileManager!
    var mockKeychainManager: MockKeychainManager!
    var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        // Create mock keychain manager
        mockKeychainManager = MockKeychainManager()
        
        // Create in-memory database manager
        do {
            databaseManager = try DatabaseManager(inMemory: true)
        } catch {
            XCTFail("Failed to create in-memory database: \(error.localizedDescription)")
            return
        }
        
        // Create profile manager
        profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: mockKeychainManager)
    }
    
    override func tearDown() {
        profileManager = nil
        mockKeychainManager = nil
        databaseManager = nil
        super.tearDown()
    }
    
    func testCreateProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters(
            temperature: 0.8,
            maxTokens: 1024,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.2
        )
        
        // When
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        // Then
        XCTAssertNotNil(createdProfile)
        XCTAssertEqual(createdProfile?.name, name)
        XCTAssertEqual(createdProfile?.apiEndpoint, apiEndpoint.absoluteString)
        XCTAssertEqual(createdProfile?.modelName, modelName)
        XCTAssertEqual(createdProfile?.parameters.temperature, parameters.temperature)
        XCTAssertEqual(createdProfile?.parameters.maxTokens, parameters.maxTokens)
        XCTAssertEqual(createdProfile?.parameters.topP, parameters.topP)
        XCTAssertEqual(createdProfile?.parameters.frequencyPenalty, parameters.frequencyPenalty)
        XCTAssertEqual(createdProfile?.parameters.presencePenalty, parameters.presencePenalty)
        
        // Verify API key was saved
        XCTAssertEqual(mockKeychainManager.getAPIKey(for: createdProfile?.id), apiKey)
        
        // Verify profile was added to the list
        XCTAssertEqual(profileManager.profiles.count, 2) // Default profile + new profile
        XCTAssertTrue(profileManager.profiles.contains { $0.id == createdProfile?.id })
    }
    
    func testUpdateProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters(
            temperature: 0.8,
            maxTokens: 1024,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.2
        )
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // When
        let updatedName = "Updated Profile"
        let updatedApiEndpoint = URL(string: "https://api.updated.com")!
        let updatedApiKey = "updated-api-key"
        let updatedModelName = "updated-model"
        let updatedParameters = ModelParameters(
            temperature: 0.5,
            maxTokens: 2048,
            topP: 0.7,
            frequencyPenalty: 0.3,
            presencePenalty: 0.4
        )
        
        XCTAssertNoThrow(try profileManager.updateProfile(
            id: profileId,
            name: updatedName,
            apiEndpoint: updatedApiEndpoint,
            apiKey: updatedApiKey,
            modelName: updatedModelName,
            parameters: updatedParameters
        ))
        
        // Then
        let updatedProfile = profileManager.profiles.first { $0.id == profileId }
        XCTAssertNotNil(updatedProfile)
        XCTAssertEqual(updatedProfile?.name, updatedName)
        XCTAssertEqual(updatedProfile?.apiEndpoint, updatedApiEndpoint.absoluteString)
        XCTAssertEqual(updatedProfile?.modelName, updatedModelName)
        XCTAssertEqual(updatedProfile?.parameters.temperature, updatedParameters.temperature)
        XCTAssertEqual(updatedProfile?.parameters.maxTokens, updatedParameters.maxTokens)
        XCTAssertEqual(updatedProfile?.parameters.topP, updatedParameters.topP)
        XCTAssertEqual(updatedProfile?.parameters.frequencyPenalty, updatedParameters.frequencyPenalty)
        XCTAssertEqual(updatedProfile?.parameters.presencePenalty, updatedParameters.presencePenalty)
        
        // Verify API key was updated
        XCTAssertEqual(mockKeychainManager.getAPIKey(for: profileId), updatedApiKey)
    }
    
    func testDeleteProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // Create another profile to be selected
        var secondProfile: ModelProfile?
        XCTAssertNoThrow(secondProfile = try profileManager.createProfile(
            name: "Second Profile",
            apiEndpoint: URL(string: "https://api.second.com")!,
            apiKey: "second-api-key",
            modelName: "second-model",
            parameters: parameters
        ))
        
        guard let secondProfileId = secondProfile?.id else {
            XCTFail("Failed to create second profile")
            return
        }
        
        // Select the second profile
        profileManager.selectProfile(id: secondProfileId)
        
        // When
        XCTAssertNoThrow(try profileManager.deleteProfile(id: profileId))
        
        // Then
        XCTAssertFalse(profileManager.profiles.contains { $0.id == profileId })
        XCTAssertNil(mockKeychainManager.getAPIKey(for: profileId))
    }
    
    func testCannotDeleteLastProfile() {
        // Given
        // Clear any existing profiles
        for profile in profileManager.profiles {
            if !profile.isDefault {
                XCTAssertNoThrow(try profileManager.deleteProfile(id: profile.id))
            }
        }
        
        // Get the default profile
        guard let defaultProfile = profileManager.profiles.first else {
            XCTFail("No default profile found")
            return
        }
        
        // When/Then
        XCTAssertThrowsError(try profileManager.deleteProfile(id: defaultProfile.id)) { error in
            XCTAssertEqual(error as? ProfileError, ProfileError.cannotDeleteLastProfile)
        }
    }
    
    func testCannotDeleteSelectedProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // Select the profile
        profileManager.selectProfile(id: profileId)
        
        // When/Then
        XCTAssertThrowsError(try profileManager.deleteProfile(id: profileId)) { error in
            XCTAssertEqual(error as? ProfileError, ProfileError.cannotDeleteSelectedProfile)
        }
    }
    
    func testSetDefaultProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // When
        XCTAssertNoThrow(try profileManager.setDefaultProfile(id: profileId))
        
        // Then
        let updatedProfile = profileManager.profiles.first { $0.id == profileId }
        XCTAssertNotNil(updatedProfile)
        XCTAssertTrue(updatedProfile!.isDefault)
        
        // Verify other profiles are not default
        for profile in profileManager.profiles {
            if profile.id != profileId {
                XCTAssertFalse(profile.isDefault)
            }
        }
    }
    
    func testDuplicateProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters(
            temperature: 0.8,
            maxTokens: 1024,
            topP: 0.9,
            frequencyPenalty: 0.1,
            presencePenalty: 0.2
        )
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // When
        var duplicatedProfile: ModelProfile?
        XCTAssertNoThrow(duplicatedProfile = try profileManager.duplicateProfile(id: profileId))
        
        // Then
        XCTAssertNotNil(duplicatedProfile)
        XCTAssertNotEqual(duplicatedProfile?.id, profileId)
        XCTAssertEqual(duplicatedProfile?.name, "\(name) (Copy)")
        XCTAssertEqual(duplicatedProfile?.apiEndpoint, apiEndpoint.absoluteString)
        XCTAssertEqual(duplicatedProfile?.modelName, modelName)
        XCTAssertEqual(duplicatedProfile?.parameters.temperature, parameters.temperature)
        XCTAssertEqual(duplicatedProfile?.parameters.maxTokens, parameters.maxTokens)
        XCTAssertEqual(duplicatedProfile?.parameters.topP, parameters.topP)
        XCTAssertEqual(duplicatedProfile?.parameters.frequencyPenalty, parameters.frequencyPenalty)
        XCTAssertEqual(duplicatedProfile?.parameters.presencePenalty, parameters.presencePenalty)
        
        // Verify API key was copied
        XCTAssertEqual(mockKeychainManager.getAPIKey(for: duplicatedProfile?.id), apiKey)
    }
    
    func testSelectProfile() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // When
        profileManager.selectProfile(id: profileId)
        
        // Then
        XCTAssertEqual(profileManager.selectedProfileId, profileId)
        XCTAssertEqual(profileManager.getSelectedProfile()?.id, profileId)
    }
    
    func testGetAPIKey() {
        // Given
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        var createdProfile: ModelProfile?
        XCTAssertNoThrow(createdProfile = try profileManager.createProfile(
            name: name,
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            parameters: parameters
        ))
        
        guard let profileId = createdProfile?.id else {
            XCTFail("Failed to create profile")
            return
        }
        
        // When
        let retrievedApiKey = profileManager.getAPIKey(for: profileId)
        
        // Then
        XCTAssertEqual(retrievedApiKey, apiKey)
    }
}
