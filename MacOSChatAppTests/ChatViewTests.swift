import XCTest
import SwiftUI
@testable import MacOSChatApp

class ChatViewTests: XCTestCase {
    var mockModelConfigManager: MockModelConfigurationManager!
    var mockDatabaseManager: MockDatabaseManager!
    var documentHandler: DocumentHandler!
    var mockProfileManager: MockProfileManager!
    var viewModel: ChatViewModel!
    var view: ChatView!
    
    override func setUp() {
        super.setUp()
        
        // Create mock dependencies
        let mockKeychainManager = MockKeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        
        mockModelConfigManager = MockModelConfigurationManager(
            keychainManager: mockKeychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        do {
            mockDatabaseManager = try MockDatabaseManager()
        } catch {
            XCTFail("Failed to initialize MockDatabaseManager: \(error.localizedDescription)")
            return
        }
        
        documentHandler = DocumentHandler()
        mockProfileManager = MockProfileManager(
            databaseManager: mockDatabaseManager,
            keychainManager: mockKeychainManager
        )
        
        viewModel = ChatViewModel(
            modelConfigManager: mockModelConfigManager,
            databaseManager: mockDatabaseManager,
            documentHandler: documentHandler,
            profileManager: mockProfileManager
        )
        
        view = ChatView(viewModel: viewModel)
    }
    
    override func tearDown() {
        mockModelConfigManager = nil
        mockDatabaseManager = nil
        documentHandler = nil
        mockProfileManager = nil
        viewModel = nil
        view = nil
        
        super.tearDown()
    }
    
    func testChatViewInitialization() {
        // Test that the view initializes correctly
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.viewModel)
    }
    
    func testChatViewModelInitialization() {
        // Test that the view model initializes correctly
        XCTAssertNotNil(viewModel)
    }
    
    func testSendMessage() {
        // Test sending a message
        let messageText = "Test message"
        viewModel.sendMessage(messageText)
        
        // Check that the message was added to the view model
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].role, "user")
        XCTAssertEqual(viewModel.messages[0].content, messageText)
    }
    
    func testProfileIntegration() {
        // Create test profiles
        let profile1 = ModelProfile(
            id: "profile-1",
            name: "Profile 1",
            modelName: "model-1",
            apiEndpoint: "https://api.example.com/v1",
            isDefault: true,
            parameters: ModelParameters(
                temperature: 0.7,
                maxTokens: 2048,
                topP: 1.0,
                frequencyPenalty: 0.0,
                presencePenalty: 0.0
            )
        )
        
        let profile2 = ModelProfile(
            id: "profile-2",
            name: "Profile 2",
            modelName: "model-2",
            apiEndpoint: "https://api.example.com/v2",
            isDefault: false,
            parameters: ModelParameters(
                temperature: 0.5,
                maxTokens: 4096,
                topP: 0.9,
                frequencyPenalty: 0.1,
                presencePenalty: 0.1
            )
        )
        
        // Add profiles to mock profile manager
        mockProfileManager.profiles = [profile1, profile2]
        
        // Set selected profile to profile 1
        mockProfileManager.selectedProfileId = profile1.id
        
        // Create a conversation
        let conversation = Conversation(
            id: "test-conversation",
            title: "Test Conversation",
            messages: [],
            createdAt: Date(),
            updatedAt: Date(),
            profileId: profile1.id
        )
        
        mockDatabaseManager.conversations = [conversation]
        mockDatabaseManager.getConversationResult = conversation
        
        // Set up profile changed handler
        mockProfileManager.profileChangedHandler = {
            // This simulates what happens when the profile changes
            if let profile = self.mockProfileManager.getSelectedProfile() {
                self.mockModelConfigManager.updateConfigurationFromProfile(profile)
                
                // Update conversation profile
                try? self.mockDatabaseManager.updateConversationProfile(
                    id: conversation.id,
                    profileId: self.mockProfileManager.selectedProfileId
                )
            }
        }
        
        // Verify initial state
        XCTAssertEqual(mockProfileManager.selectedProfileId, profile1.id)
        
        // Change selected profile to profile 2
        mockProfileManager.selectedProfileId = profile2.id
        
        // Notify observers of the change
        mockProfileManager.notifyProfileChanged()
        
        // Wait for async operation to complete
        let expectation = XCTestExpectation(description: "Profile change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the model config manager was updated with profile 2 settings
        XCTAssertEqual(mockModelConfigManager.lastUpdatedEndpoint?.absoluteString, profile2.apiEndpoint)
        XCTAssertEqual(mockModelConfigManager.lastUpdatedModelName, profile2.modelName)
        XCTAssertEqual(mockModelConfigManager.lastUpdatedParameters?.temperature, profile2.parameters.temperature)
        XCTAssertEqual(mockModelConfigManager.lastUpdatedParameters?.maxTokens, profile2.parameters.maxTokens)
        
        // Verify that the conversation profile was updated
        XCTAssertEqual(mockDatabaseManager.lastUpdatedConversationProfileId, profile2.id)
    }
}
