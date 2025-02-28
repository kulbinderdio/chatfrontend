import XCTest
@testable import MacOSChatApp

class DatabaseManagerClearHistoryTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        // Use an in-memory database for testing
        do {
            databaseManager = try DatabaseManager(inMemory: true)
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        databaseManager = nil
        super.tearDown()
    }
    
    func testDeleteAllConversations() {
        // Create some test conversations
        let conversation1 = databaseManager.createConversation(title: "Test Conversation 1")
        let conversation2 = databaseManager.createConversation(title: "Test Conversation 2")
        let conversation3 = databaseManager.createConversation(title: "Test Conversation 3")
        
        // Add some messages to the conversations
        let message1 = Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())
        let message2 = Message(id: UUID().uuidString, role: "assistant", content: "Hi there", timestamp: Date())
        
        databaseManager.addMessage(message1, toConversation: conversation1.id)
        databaseManager.addMessage(message2, toConversation: conversation1.id)
        
        // Verify that conversations and messages were added
        XCTAssertEqual(databaseManager.getConversationCount(), 3, "Should have 3 conversations")
        XCTAssertEqual(databaseManager.getMessages(forConversation: conversation1.id).count, 2, "Should have 2 messages in conversation 1")
        
        // Delete all conversations
        do {
            try databaseManager.deleteAllConversations()
            
            // Verify that all conversations were deleted
            XCTAssertEqual(databaseManager.getConversationCount(), 0, "Should have 0 conversations after deletion")
            
            // Verify that all messages were deleted
            XCTAssertEqual(databaseManager.getMessages(forConversation: conversation1.id).count, 0, "Should have 0 messages in conversation 1 after deletion")
        } catch {
            XCTFail("Failed to delete all conversations: \(error.localizedDescription)")
        }
    }
    
    func testSettingsViewModelClearConversationHistory() {
        // Create dependencies
        let keychainManager = KeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        let modelConfigManager = ModelConfigurationManager(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        // Create the view model
        let viewModel = SettingsViewModel(
            modelConfigManager: modelConfigManager,
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager,
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        // Create some test conversations
        let conversation1 = databaseManager.createConversation(title: "Test Conversation 1")
        let conversation2 = databaseManager.createConversation(title: "Test Conversation 2")
        
        // Add some messages to the conversations
        let message1 = Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())
        databaseManager.addMessage(message1, toConversation: conversation1.id)
        
        // Verify that conversations and messages were added
        XCTAssertEqual(databaseManager.getConversationCount(), 2, "Should have 2 conversations")
        
        // Set up an expectation for the notification
        let expectation = XCTestExpectation(description: "ConversationHistoryCleared notification")
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("ConversationHistoryCleared"),
            object: nil,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }
        
        // Call the clearConversationHistory method
        viewModel.clearConversationHistory()
        
        // Wait for the notification and async operations to complete
        wait(for: [expectation], timeout: 2.0)
        
        // Add a small delay to ensure all async operations complete
        let asyncExpectation = XCTestExpectation(description: "Wait for async operations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            asyncExpectation.fulfill()
        }
        wait(for: [asyncExpectation], timeout: 1.0)
        
        // Verify that all conversations were deleted
        XCTAssertEqual(databaseManager.getConversationCount(), 0, "Should have 0 conversations after clearing history")
        
        // Clean up
        NotificationCenter.default.removeObserver(observer)
    }
    
    func testConversationListViewModelHandleConversationHistoryCleared() {
        // Create dependencies
        let keychainManager = KeychainManager()
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        // Create the view model
        let viewModel = ConversationListViewModel(databaseManager: databaseManager, profileManager: profileManager)
        
        // Create some test conversations
        let conversation1 = databaseManager.createConversation(title: "Test Conversation 1")
        let conversation2 = databaseManager.createConversation(title: "Test Conversation 2")
        
        // Verify that conversations were added to the view model
        XCTAssertEqual(viewModel.conversations.count, 2, "Should have 2 conversations in the view model")
        
        // Post the notification to clear conversation history
        NotificationCenter.default.post(name: Notification.Name("ConversationHistoryCleared"), object: nil)
        
        // Wait for the async operations to complete
        let expectation = XCTestExpectation(description: "Wait for async operations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify that the view model has cleared its conversations and created a new one
        XCTAssertEqual(viewModel.conversations.count, 1, "Should have 1 conversation (the new one) after clearing history")
        XCTAssertEqual(databaseManager.getConversationCount(), 1, "Should have 1 conversation in the database after clearing history")
    }
}
