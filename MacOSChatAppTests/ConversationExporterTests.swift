import XCTest
@testable import MacOSChatApp

class ConversationExporterTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var exporter: ConversationExporter!
    var testConversation: Conversation!
    
    override func setUp() {
        super.setUp()
        
        // Create database manager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            XCTFail("Failed to initialize DatabaseManager: \(error.localizedDescription)")
            return
        }
        
        // Create exporter
        exporter = ConversationExporter(databaseManager: databaseManager)
        
        // Create test conversation
        let messages = [
            Message(role: "user", content: "Hello"),
            Message(role: "assistant", content: "Hi there! How can I help you today?"),
            Message(role: "user", content: "What's the weather like?"),
            Message(role: "assistant", content: "I don't have access to real-time weather information. You would need to check a weather service or app for that information.")
        ]
        
        testConversation = Conversation(
            id: "test-conversation",
            title: "Test Conversation",
            messages: messages,
            createdAt: Date(),
            updatedAt: Date(),
            profileId: nil
        )
    }
    
    override func tearDown() {
        databaseManager = nil
        exporter = nil
        testConversation = nil
        
        super.tearDown()
    }
    
    func testExportConversation() {
        // Test exporting a conversation
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test-conversation.json")
        
        // Export the conversation
        do {
            try exporter.exportConversation(testConversation, to: fileURL, format: .json)
            
            // Check that the file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            // Check file contents
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            XCTAssertNotNil(json)
            XCTAssertEqual(json?["id"] as? String, testConversation.id)
            XCTAssertEqual(json?["title"] as? String, testConversation.title)
            
            // Check messages
            let messagesData = json?["messages"] as? [[String: Any]]
            XCTAssertNotNil(messagesData)
            XCTAssertEqual(messagesData?.count, testConversation.messages.count)
            
            // Clean up
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            XCTFail("Failed to export conversation: \(error.localizedDescription)")
        }
    }
    
    func testImportConversation() {
        // Test importing a conversation
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test-conversation.json")
        
        // Export the conversation first
        do {
            try exporter.exportConversation(testConversation, to: fileURL, format: .json)
            
            // Import the conversation
            let importedConversation = try exporter.importConversation(from: fileURL)
            
            // Check that the imported conversation matches the original
            XCTAssertEqual(importedConversation.id, testConversation.id)
            XCTAssertEqual(importedConversation.title, testConversation.title)
            XCTAssertEqual(importedConversation.messages.count, testConversation.messages.count)
            
            // Check messages
            for i in 0..<testConversation.messages.count {
                XCTAssertEqual(importedConversation.messages[i].id, testConversation.messages[i].id)
                XCTAssertEqual(importedConversation.messages[i].role, testConversation.messages[i].role)
                XCTAssertEqual(importedConversation.messages[i].content, testConversation.messages[i].content)
            }
            
            // Clean up
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            XCTFail("Failed to import conversation: \(error.localizedDescription)")
        }
    }
    
    func testExportAllConversations() {
        // Test exporting all conversations
        let tempDir = FileManager.default.temporaryDirectory
        let directoryURL = tempDir.appendingPathComponent("conversations")
        
        // Export all conversations
        do {
            try exporter.exportAllConversations(to: directoryURL)
            
            // Check that the directory exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: directoryURL.path))
            
            // Clean up
            try FileManager.default.removeItem(at: directoryURL)
        } catch {
            XCTFail("Failed to export all conversations: \(error.localizedDescription)")
        }
    }
}
