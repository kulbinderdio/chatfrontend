import XCTest
@testable import MacOSChatApp

class DatabaseManagerTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    
    override func setUp() {
        super.setUp()
        
        do {
            databaseManager = try DatabaseManager()
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        databaseManager = nil
        super.tearDown()
    }
    
    // MARK: - Conversation Tests
    
    func testCreateAndGetConversation() {
        // Create a conversation
        let title = "Test Conversation"
        let conversation = databaseManager.createConversation(title: title)
        
        // Get the conversation
        if let retrievedConversation = databaseManager.getConversation(id: conversation.id) {
            XCTAssertEqual(retrievedConversation.id, conversation.id)
            XCTAssertEqual(retrievedConversation.title, title)
            XCTAssertEqual(retrievedConversation.messages.count, 0)
        } else {
            XCTFail("Failed to retrieve conversation")
        }
    }
    
    func testUpdateConversationTitle() {
        // Create a conversation
        let conversation = databaseManager.createConversation(title: "Original Title")
        
        // Update the title
        let newTitle = "Updated Title"
        do {
            try databaseManager.updateConversationTitle(id: conversation.id, title: newTitle)
            
            // Get the updated conversation
            if let updatedConversation = databaseManager.getConversation(id: conversation.id) {
                XCTAssertEqual(updatedConversation.title, newTitle)
            } else {
                XCTFail("Failed to retrieve updated conversation")
            }
        } catch {
            XCTFail("Failed to update conversation title: \(error.localizedDescription)")
        }
    }
    
    func testDeleteConversation() {
        // Create a conversation
        let conversation = databaseManager.createConversation(title: "Conversation to Delete")
        
        // Delete the conversation
        do {
            try databaseManager.deleteConversation(id: conversation.id)
            
            // Try to get the deleted conversation
            let deletedConversation = databaseManager.getConversation(id: conversation.id)
            XCTAssertNil(deletedConversation, "Conversation should be deleted")
        } catch {
            XCTFail("Failed to delete conversation: \(error.localizedDescription)")
        }
    }
    
    func testUpdateConversationProfile() {
        // Create a conversation
        let conversation = databaseManager.createConversation(title: "Conversation with Profile")
        
        // Create a profile
        let profile = ModelProfile(
            name: "Test Profile",
            modelName: "test-model",
            apiEndpoint: "https://api.example.com",
            isDefault: false,
            parameters: ModelParameters(
                temperature: 0.7,
                maxTokens: 1000,
                topP: 1.0,
                frequencyPenalty: 0.0,
                presencePenalty: 0.0
            )
        )
        
        do {
            // Update the conversation's profile
            try databaseManager.updateConversationProfile(id: conversation.id, profileId: profile.id)
            
            // Get the updated conversation
            if let updatedConversation = databaseManager.getConversation(id: conversation.id) {
                XCTAssertEqual(updatedConversation.profileId, profile.id)
            } else {
                XCTFail("Failed to retrieve updated conversation")
            }
            
            // Update the conversation's profile to nil
            try databaseManager.updateConversationProfile(id: conversation.id, profileId: nil)
            
            // Get the updated conversation
            if let updatedConversation = databaseManager.getConversation(id: conversation.id) {
                XCTAssertNil(updatedConversation.profileId)
            } else {
                XCTFail("Failed to retrieve updated conversation")
            }
        } catch {
            XCTFail("Failed to update conversation profile: \(error.localizedDescription)")
        }
    }
    
    func testGetAllConversations() {
        // Create a few conversations
        let conversation1 = databaseManager.createConversation(title: "Conversation 1")
        let conversation2 = databaseManager.createConversation(title: "Conversation 2")
        let conversation3 = databaseManager.createConversation(title: "Conversation 3")
        
        // Get all conversations
        let conversations = databaseManager.getAllConversations()
        
        // Check that the conversations are returned
        XCTAssertTrue(conversations.contains(where: { $0.id == conversation1.id }))
        XCTAssertTrue(conversations.contains(where: { $0.id == conversation2.id }))
        XCTAssertTrue(conversations.contains(where: { $0.id == conversation3.id }))
    }
    
    // MARK: - Message Tests
    
    func testAddAndGetMessages() {
        // Create a conversation
        let conversation = databaseManager.createConversation(title: "Conversation with Messages")
        
        // Add messages
        let message1 = Message(id: UUID().uuidString, role: "user", content: "Hello", timestamp: Date())
        let message2 = Message(id: UUID().uuidString, role: "assistant", content: "Hi there! How can I help you?", timestamp: Date())
        
        databaseManager.addMessage(message1, toConversation: conversation.id)
        databaseManager.addMessage(message2, toConversation: conversation.id)
        
        // Get messages
        let messages = databaseManager.getMessages(forConversation: conversation.id)
        
        // Check that the messages are returned
        XCTAssertEqual(messages.count, 2)
        XCTAssertTrue(messages.contains(where: { $0.content == message1.content && $0.role == message1.role }))
        XCTAssertTrue(messages.contains(where: { $0.content == message2.content && $0.role == message2.role }))
    }
    
    // MARK: - Search Tests
    
    func testSearchConversations() {
        // Create conversations with different titles
        let conversation1 = databaseManager.createConversation(title: "Apple Discussion")
        let conversation2 = databaseManager.createConversation(title: "Banana Recipes")
        let conversation3 = databaseManager.createConversation(title: "Cherry Picking")
        
        // Add messages to the conversations
        databaseManager.addMessage(Message(id: UUID().uuidString, role: "user", content: "I love apples", timestamp: Date()), toConversation: conversation1.id)
        databaseManager.addMessage(Message(id: UUID().uuidString, role: "user", content: "Bananas are great", timestamp: Date()), toConversation: conversation2.id)
        databaseManager.addMessage(Message(id: UUID().uuidString, role: "user", content: "Cherries are my favorite", timestamp: Date()), toConversation: conversation3.id)
        
        // Search for "apple"
        let appleResults = databaseManager.searchConversations(query: "apple")
        XCTAssertTrue(appleResults.contains(where: { $0.id == conversation1.id }))
        XCTAssertFalse(appleResults.contains(where: { $0.id == conversation2.id }))
        XCTAssertFalse(appleResults.contains(where: { $0.id == conversation3.id }))
        
        // Search for "banana"
        let bananaResults = databaseManager.searchConversations(query: "banana")
        XCTAssertFalse(bananaResults.contains(where: { $0.id == conversation1.id }))
        XCTAssertTrue(bananaResults.contains(where: { $0.id == conversation2.id }))
        XCTAssertFalse(bananaResults.contains(where: { $0.id == conversation3.id }))
    }
}
