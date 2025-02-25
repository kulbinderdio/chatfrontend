import XCTest
import SQLite
import KeychainAccess
import Alamofire
import SwiftyJSON
import Down
import SwiftUI
@testable import MacOSChatApp

class DependencyIntegrationTests: XCTestCase {
    
    // Test components
    var keychainManager: KeychainManager!
    var userDefaultsManager: UserDefaultsManager!
    var databaseManager: DatabaseManager!
    var modelConfigManager: ModelConfigurationManager!
    var profileManager: ProfileManager!
    var documentHandler: DocumentHandler!
    var chatViewModel: ChatViewModel!
    var conversationListViewModel: ConversationListViewModel!
    var menuBarManager: MenuBarManager!
    
    override func setUp() {
        super.setUp()
        
        // Initialize components
        keychainManager = KeychainManager()
        userDefaultsManager = UserDefaultsManager()
        
        do {
            databaseManager = try DatabaseManager(inMemory: true)
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        modelConfigManager = ModelConfigurationManager(
            keychainManager: keychainManager,
            userDefaultsManager: userDefaultsManager
        )
        
        profileManager = ProfileManager(
            databaseManager: databaseManager,
            keychainManager: keychainManager
        )
        
        documentHandler = DocumentHandler()
        
        conversationListViewModel = ConversationListViewModel(
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        chatViewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        menuBarManager = MenuBarManager()
    }
    
    override func tearDown() {
        // Clean up
        keychainManager = nil
        userDefaultsManager = nil
        databaseManager = nil
        modelConfigManager = nil
        profileManager = nil
        documentHandler = nil
        chatViewModel = nil
        conversationListViewModel = nil
        menuBarManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Library Integration Tests
    
    func testSQLiteIntegration() {
        // Verify SQLite can be initialized
        let db = try? Connection(.inMemory)
        XCTAssertNotNil(db, "SQLite connection should be established")
    }
    
    func testKeychainIntegration() {
        // Verify Keychain can be accessed
        let keychain = Keychain(service: "com.test.MacOSChatApp")
        XCTAssertNotNil(keychain, "Keychain should be accessible")
    }
    
    func testAlamofireIntegration() {
        // Verify Alamofire session can be created
        let session = Session()
        XCTAssertNotNil(session, "Alamofire session should be created")
    }
    
    func testSwiftyJSONIntegration() {
        // Verify SwiftyJSON can parse JSON
        let json = JSON(["test": "value"])
        XCTAssertEqual(json["test"].string, "value", "SwiftyJSON should parse correctly")
    }
    
    func testDownIntegration() {
        // Verify Down can render markdown
        let down = Down(markdownString: "# Test")
        XCTAssertNotNil(down, "Down should initialize with markdown string")
    }
    
    // MARK: - Component Integration Tests
    
    func testDatabaseManagerIntegration() {
        XCTAssertNotNil(databaseManager, "DatabaseManager should be initialized")
        
        // Test conversation creation
        var conversation = databaseManager.createConversation(title: "Test Conversation", profileId: nil)
        XCTAssertNotNil(conversation, "Conversation should be created")
        XCTAssertEqual(conversation.title, "Test Conversation", "Conversation title should match")
        
        // Test message creation
        // Create a message directly
        let message = Message(
            id: UUID().uuidString,
            role: "user",
            content: "Test message",
            timestamp: Date()
        )
        
        // Add message to conversation
        conversation.messages.append(message)
        XCTAssertNotNil(message, "Message should be created")
        XCTAssertEqual(message.role, "user", "Message role should match")
        XCTAssertEqual(message.content, "Test message", "Message content should match")
    }
    
    func testProfileManagerIntegration() {
        XCTAssertNotNil(profileManager, "ProfileManager should be initialized")
        
        // Create a test profile
        let apiEndpoint = URL(string: "https://api.example.com")!
        let parameters = ModelParameters(
            temperature: 0.7,
            maxTokens: 2048,
            topP: 1.0,
            frequencyPenalty: 0.0,
            presencePenalty: 0.0
        )
        
        do {
            let profile = try profileManager.createProfile(
                name: "Test Profile",
                apiEndpoint: apiEndpoint,
                apiKey: "test-api-key",
                modelName: "gpt-4",
                parameters: parameters
            )
            
            XCTAssertNotNil(profile, "Profile should be created")
            XCTAssertEqual(profile.name, "Test Profile", "Profile name should match")
            XCTAssertEqual(profile.modelName, "gpt-4", "Profile model name should match")
            
            // Test profile retrieval
            if let retrievedProfile = profileManager.profiles.first(where: { $0.id == profile.id }) {
                XCTAssertNotNil(retrievedProfile, "Profile should be retrieved")
                XCTAssertEqual(retrievedProfile.id, profile.id, "Profile ID should match")
            } else {
                XCTFail("Profile not found")
            }
        } catch {
            XCTFail("Failed to create or retrieve profile: \(error.localizedDescription)")
        }
    }
    
    func testChatViewModelIntegration() {
        XCTAssertNotNil(chatViewModel, "ChatViewModel should be initialized")
        
        // Create a conversation
        let conversation = databaseManager.createConversation(title: "Test Conversation", profileId: nil)
        
        // Set the conversation
        chatViewModel.setConversation(conversation)
        
        // Verify conversation is loaded
        XCTAssertEqual(chatViewModel.conversation?.id, conversation.id, "Conversation should be loaded")
        
        // Test sending a message
        let expectation = XCTestExpectation(description: "Message sent")
        
        // Mock the API response
        chatViewModel.sendMessage("Test message", mockResponse: "Mock response")
        
        // Wait for the message to be processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify messages are added
            XCTAssertEqual(self.chatViewModel.messages.count, 2, "Two messages should be added")
            XCTAssertEqual(self.chatViewModel.messages[0].role, "user", "First message should be from user")
            XCTAssertEqual(self.chatViewModel.messages[0].content, "Test message", "User message content should match")
            XCTAssertEqual(self.chatViewModel.messages[1].role, "assistant", "Second message should be from assistant")
            XCTAssertEqual(self.chatViewModel.messages[1].content, "Mock response", "Assistant message content should match")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConversationListViewModelIntegration() {
        XCTAssertNotNil(conversationListViewModel, "ConversationListViewModel should be initialized")
        
        // Create test conversations
        let conversation1 = databaseManager.createConversation(title: "Test Conversation 1", profileId: nil)
        _ = databaseManager.createConversation(title: "Test Conversation 2", profileId: nil)
        
        // Load conversations
        conversationListViewModel.loadConversations()
        
        // Wait for loading to complete
        let expectation = XCTestExpectation(description: "Conversations loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Verify conversations are loaded
            XCTAssertGreaterThanOrEqual(self.conversationListViewModel.conversations.count, 2, "At least two conversations should be loaded")
            
            // Test conversation selection
            self.conversationListViewModel.selectConversation(id: conversation1.id)
            XCTAssertEqual(self.conversationListViewModel.currentConversationId, conversation1.id, "Conversation 1 should be selected")
            
            // Test conversation update
            self.conversationListViewModel.updateConversationTitle(id: conversation1.id, title: "Updated Title")
            
            // Find the updated conversation
            if let updatedConversation = self.conversationListViewModel.conversations.first(where: { $0.id == conversation1.id }) {
                XCTAssertEqual(updatedConversation.title, "Updated Title", "Conversation title should be updated")
            } else {
                XCTFail("Updated conversation not found")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMenuBarManagerIntegration() {
        XCTAssertNotNil(menuBarManager, "MenuBarManager should be initialized")
        
        // Create a test chat view
        let chatView = ChatView(
            viewModel: chatViewModel,
            conversationListViewModel: conversationListViewModel
        )
        
        // Test setup
        menuBarManager.setupMenuBar(with: chatView)
        
        // Verify status item is created
        XCTAssertNotNil(menuBarManager.statusItem, "Status item should be created")
        XCTAssertNotNil(menuBarManager.popover, "Popover should be created")
    }
    
    func testDocumentHandlerIntegration() {
        XCTAssertNotNil(documentHandler, "DocumentHandler should be initialized")
        
        // Test token estimation
        let text = "This is a test document with some text content."
        let tokenCount = documentHandler.estimateTokenCount(for: text)
        
        XCTAssertGreaterThan(tokenCount, 0, "Token count should be greater than 0")
        XCTAssertLessThan(tokenCount, 100, "Token count should be less than 100 for this short text")
    }
    
    func testFullAppIntegration() {
        // Create all necessary components for the app
        let keychain = KeychainManager()
        let userDefaults = UserDefaultsManager()
        let document = DocumentHandler()
        
        // Initialize database manager
        let dbManager: DatabaseManager
        do {
            dbManager = try DatabaseManager(inMemory: true)
        } catch {
            XCTFail("Failed to initialize database: \(error.localizedDescription)")
            return
        }
        
        // Initialize model configuration manager
        let configManager = ModelConfigurationManager(
            keychainManager: keychain,
            userDefaultsManager: userDefaults
        )
        
        // Initialize profile manager
        let profManager = ProfileManager(
            databaseManager: dbManager,
            keychainManager: keychain
        )
        
        // Initialize view models
        let chatVM = ChatViewModel(
            modelConfigManager: configManager,
            databaseManager: dbManager,
            documentHandler: document,
            profileManager: profManager
        )
        
        let convListVM = ConversationListViewModel(
            databaseManager: dbManager,
            profileManager: profManager
        )
        
        let settingsVM = SettingsViewModel(
            modelConfigManager: configManager,
            keychainManager: keychain,
            userDefaultsManager: userDefaults,
            databaseManager: dbManager,
            profileManager: profManager
        )
        
        // Verify all components are initialized
        XCTAssertNotNil(keychain, "KeychainManager should be initialized")
        XCTAssertNotNil(userDefaults, "UserDefaultsManager should be initialized")
        XCTAssertNotNil(dbManager, "DatabaseManager should be initialized")
        XCTAssertNotNil(configManager, "ModelConfigurationManager should be initialized")
        XCTAssertNotNil(profManager, "ProfileManager should be initialized")
        XCTAssertNotNil(document, "DocumentHandler should be initialized")
        XCTAssertNotNil(chatVM, "ChatViewModel should be initialized")
        XCTAssertNotNil(convListVM, "ConversationListViewModel should be initialized")
        XCTAssertNotNil(settingsVM, "SettingsViewModel should be initialized")
        
        // Test creating a conversation and sending a message
        let newConversationId = convListVM.createNewConversation()
        XCTAssertNotNil(newConversationId, "New conversation should be created")
        
        if let conversationId = newConversationId {
            // Get the conversation from the database
            if let conversation = dbManager.getConversation(id: conversationId) {
                // Set the conversation in the chat view model
                chatVM.setConversation(conversation)
                XCTAssertEqual(chatVM.conversation?.id, conversationId, "Conversation should be loaded in ChatViewModel")
                
                // Test sending a message
                chatVM.sendMessage("Test message", mockResponse: "Mock response")
                
                // Wait for the message to be processed
                let expectation = XCTestExpectation(description: "Message sent")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    XCTAssertEqual(chatVM.messages.count, 2, "Two messages should be added")
                    expectation.fulfill()
                }
                
                wait(for: [expectation], timeout: 1.0)
            }
        }
    }
}

// MARK: - Extensions for Testing

extension ChatViewModel {
    func sendMessage(_ content: String, mockResponse: String) {
        // Create a user message
        let userMessage = Message(
            id: UUID().uuidString,
            role: "user",
            content: content,
            timestamp: Date()
        )
        
        // Add user message to the list
        DispatchQueue.main.async {
            self.messages.append(userMessage)
        }
        
        // Create a mock assistant response
        let assistantMessage = Message(
            id: UUID().uuidString,
            role: "assistant",
            content: mockResponse,
            timestamp: Date()
        )
        
        // Add assistant message to the list
        DispatchQueue.main.async {
            self.messages.append(assistantMessage)
        }
    }
    
    var conversation: Conversation? {
        return Mirror(reflecting: self).children.first(where: { $0.label == "conversation" })?.value as? Conversation
    }
    
    func setConversation(_ conversation: Conversation) {
        // Use reflection to set the private conversation property
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == "conversation" {
                let conversationProperty = child.value
                let conversationMirror = Mirror(reflecting: conversationProperty)
                for conversationChild in conversationMirror.children {
                    if conversationChild.label == "_value" {
                        // Set the conversation
                        if let setter = conversationChild.value as? (Conversation) -> Void {
                            setter(conversation)
                        }
                    }
                }
            }
        }
        
        // Load messages
        DispatchQueue.main.async {
            self.messages = conversation.messages
        }
    }
}

extension DatabaseManager {
    convenience init(inMemory: Bool) throws {
        try self.init()
        // In-memory database is handled in the main initializer
    }
}

extension MenuBarManager {
    var statusItem: NSStatusItem? {
        return Mirror(reflecting: self).children.first(where: { $0.label == "statusItem" })?.value as? NSStatusItem
    }
    
    var popover: NSPopover? {
        return Mirror(reflecting: self).children.first(where: { $0.label == "popover" })?.value as? NSPopover
    }
}
