import XCTest
import SwiftUI
@testable import MacOSChatApp

class ProfilesViewTests: XCTestCase {
    var mockKeychainManager: MockKeychainManager!
    var databaseManager: DatabaseManager!
    var profileManager: ProfileManager!
    
    override func setUp() {
        super.setUp()
        
        // Create mock dependencies
        mockKeychainManager = MockKeychainManager()
        
        do {
            databaseManager = try DatabaseManager(inMemory: true)
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        profileManager = ProfileManager(
            databaseManager: databaseManager,
            keychainManager: mockKeychainManager
        )
        
        // Clear any existing profiles
        for profile in profileManager.profiles {
            if !profile.isDefault {
                do {
                    try profileManager.deleteProfile(id: profile.id)
                } catch {
                    // Ignore errors during setup
                }
            }
        }
    }
    
    override func tearDown() {
        mockKeychainManager = nil
        databaseManager = nil
        profileManager = nil
        
        super.tearDown()
    }
    
    func testProfilesViewInitialization() {
        // Test that the view initializes correctly
        let view = ProfilesView(profileManager: profileManager)
        
        XCTAssertNotNil(view)
    }
    
    func testProfileEditorViewInitialization() {
        // Test that the profile editor view initializes correctly
        let view = ProfileEditorView(
            profileManager: profileManager,
            mode: .add
        )
        
        XCTAssertNotNil(view)
    }
    
    func testProfileEditorViewEditMode() {
        // Test that the profile editor view initializes correctly in edit mode
        // Create a test profile
        let profile = ModelProfile(
            id: "test-profile",
            name: "Test Profile",
            modelName: "test-model",
            apiEndpoint: "https://api.example.com",
            isDefault: false,
            parameters: ModelParameters(
                temperature: 0.7,
                maxTokens: 2048,
                topP: 1.0,
                frequencyPenalty: 0.0,
                presencePenalty: 0.0
            )
        )
        
        let view = ProfileEditorView(
            profileManager: profileManager,
            mode: .edit(profile: profile)
        )
        
        XCTAssertNotNil(view)
    }
    
    func testProfileAddingAndEditing() {
        // Create a test profile
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        // Add the profile
        var createdProfile: ModelProfile?
        do {
            createdProfile = try profileManager.createProfile(
                name: name,
                apiEndpoint: apiEndpoint,
                apiKey: apiKey,
                modelName: modelName,
                parameters: parameters
            )
            
            // Verify profile was added
            XCTAssertNotNil(createdProfile)
            XCTAssertEqual(createdProfile?.name, name)
            XCTAssertEqual(createdProfile?.apiEndpoint, apiEndpoint.absoluteString)
            XCTAssertEqual(createdProfile?.modelName, modelName)
            
            // Edit the profile
            let updatedName = "Updated Profile"
            let updatedApiEndpoint = URL(string: "https://api.updated.com")!
            let updatedApiKey = "updated-api-key"
            let updatedModelName = "updated-model"
            let updatedParameters = ModelParameters(
                temperature: 0.5,
                maxTokens: 1024,
                topP: 0.8,
                frequencyPenalty: 0.1,
                presencePenalty: 0.1
            )
            
            guard let profileId = createdProfile?.id else {
                XCTFail("Profile ID is nil")
                return
            }
            
            try profileManager.updateProfile(
                id: profileId,
                name: updatedName,
                apiEndpoint: updatedApiEndpoint,
                apiKey: updatedApiKey,
                modelName: updatedModelName,
                parameters: updatedParameters
            )
            
            // Verify profile was updated
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
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
    }
    
    func testProfileDeletion() {
        // Create a test profile
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters()
        
        // Add the profile
        var createdProfile: ModelProfile?
        do {
            createdProfile = try profileManager.createProfile(
                name: name,
                apiEndpoint: apiEndpoint,
                apiKey: apiKey,
                modelName: modelName,
                parameters: parameters
            )
            
            guard let profileId = createdProfile?.id else {
                XCTFail("Profile ID is nil")
                return
            }
            
            // Create another profile to be selected
            let secondProfile = try profileManager.createProfile(
                name: "Second Profile",
                apiEndpoint: URL(string: "https://api.second.com")!,
                apiKey: "second-api-key",
                modelName: "second-model",
                parameters: parameters
            )
            
            let secondProfileId = secondProfile.id
            
            // Select the second profile
            profileManager.selectProfile(id: secondProfileId)
            
            // Delete the first profile
            try profileManager.deleteProfile(id: profileId)
            
            // Verify profile was deleted
            XCTAssertFalse(profileManager.profiles.contains { $0.id == profileId })
            XCTAssertNil(mockKeychainManager.getAPIKey(for: profileId))
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
    }
    
    func testDefaultProfileSetting() {
        // Create two test profiles
        let profile1Name = "Profile 1"
        let profile2Name = "Profile 2"
        
        do {
            let profile1 = try profileManager.createProfile(
                name: profile1Name,
                apiEndpoint: URL(string: "https://api.example.com")!,
                apiKey: "api-key-1",
                modelName: "model-1",
                parameters: ModelParameters()
            )
            
            let profile2 = try profileManager.createProfile(
                name: profile2Name,
                apiEndpoint: URL(string: "https://api.example.com")!,
                apiKey: "api-key-2",
                modelName: "model-2",
                parameters: ModelParameters()
            )
            
            let profile1Id = profile1.id
            let profile2Id = profile2.id
            
            // Set profile 2 as default
            try profileManager.setDefaultProfile(id: profile2Id)
            
            // Verify profile 2 is default
            let updatedProfile2 = profileManager.profiles.first { $0.id == profile2Id }
            XCTAssertNotNil(updatedProfile2)
            XCTAssertTrue(updatedProfile2!.isDefault)
            
            // Verify profile 1 is not default
            let updatedProfile1 = profileManager.profiles.first { $0.id == profile1Id }
            XCTAssertNotNil(updatedProfile1)
            XCTAssertFalse(updatedProfile1!.isDefault)
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
    }
    
    func testProfileSelection() {
        // Create two test profiles
        let profile1Name = "Profile 1"
        let profile2Name = "Profile 2"
        
        do {
            let profile1 = try profileManager.createProfile(
                name: profile1Name,
                apiEndpoint: URL(string: "https://api.example.com")!,
                apiKey: "api-key-1",
                modelName: "model-1",
                parameters: ModelParameters()
            )
            
            let profile2 = try profileManager.createProfile(
                name: profile2Name,
                apiEndpoint: URL(string: "https://api.example.com")!,
                apiKey: "api-key-2",
                modelName: "model-2",
                parameters: ModelParameters()
            )
            
            let profile1Id = profile1.id
            let profile2Id = profile2.id
            
            // Select profile 2
            profileManager.selectProfile(id: profile2Id)
            
            // Verify profile 2 is selected
            XCTAssertEqual(profileManager.selectedProfileId, profile2Id)
            XCTAssertEqual(profileManager.getSelectedProfile()?.id, profile2Id)
            
            // Select profile 1
            profileManager.selectProfile(id: profile1Id)
            
            // Verify profile 1 is selected
            XCTAssertEqual(profileManager.selectedProfileId, profile1Id)
            XCTAssertEqual(profileManager.getSelectedProfile()?.id, profile1Id)
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
    }
    
    func testProfileDuplication() {
        // Create a test profile
        let name = "Test Profile"
        let apiEndpoint = URL(string: "https://api.example.com")!
        let apiKey = "test-api-key"
        let modelName = "test-model"
        let parameters = ModelParameters(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        do {
            let originalProfile = try profileManager.createProfile(
                name: name,
                apiEndpoint: apiEndpoint,
                apiKey: apiKey,
                modelName: modelName,
                parameters: parameters
            )
            
            let profileId = originalProfile.id
            
            // Duplicate the profile
            let duplicatedProfile = try profileManager.duplicateProfile(id: profileId)
            
            // Verify the duplicated profile
            XCTAssertNotNil(duplicatedProfile)
            XCTAssertNotEqual(duplicatedProfile.id, profileId)
            XCTAssertEqual(duplicatedProfile.name, "\(name) (Copy)")
            XCTAssertEqual(duplicatedProfile.apiEndpoint, apiEndpoint.absoluteString)
            XCTAssertEqual(duplicatedProfile.modelName, modelName)
            XCTAssertEqual(duplicatedProfile.parameters.temperature, parameters.temperature)
            XCTAssertEqual(duplicatedProfile.parameters.maxTokens, parameters.maxTokens)
            XCTAssertEqual(duplicatedProfile.parameters.topP, parameters.topP)
            XCTAssertEqual(duplicatedProfile.parameters.frequencyPenalty, parameters.frequencyPenalty)
            XCTAssertEqual(duplicatedProfile.parameters.presencePenalty, parameters.presencePenalty)
            
            // Verify API key was copied
            XCTAssertEqual(mockKeychainManager.getAPIKey(for: duplicatedProfile.id), apiKey)
        } catch {
            XCTFail("Test failed with error: \(error)")
        }
    }
}
