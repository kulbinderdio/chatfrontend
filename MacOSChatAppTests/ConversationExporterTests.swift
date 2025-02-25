import XCTest
@testable import MacOSChatApp

class ConversationExporterTests: XCTestCase {
    
    var databaseManager: DatabaseManager!
    var exporter: ConversationExporter!
    
    override func setUp() {
        super.setUp()
        
        do {
            databaseManager = try DatabaseManager()
            exporter = ConversationExporter(databaseManager: databaseManager)
        } catch {
            XCTFail("Failed to initialize: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        exporter = nil
        databaseManager = nil
        super.tearDown()
    }
    
    func testExportAsPlainText() {
        // Create a conversation with messages
        let conversation = databaseManager.createConversation(title: "Test Conversation")
        
        // Add messages
        let message1 = Message(role: "user", content: "Hello")
        let message2 = Message(role: "assistant", content: "Hi there! How can I help you?")
        
        databaseManager.addMessage(message1, toConversation: conversation.id)
        databaseManager.addMessage(message2, toConversation: conversation.id)
        
        // Export as plain text
        if let fileURL = exporter.exportConversation(id: conversation.id, format: .plainText) {
            // Check that the file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            // Check the file content
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                
                // Verify the content contains the conversation title
                XCTAssertTrue(content.contains("Test Conversation"))
                
                // Verify the content contains the messages
                XCTAssertTrue(content.contains("Hello"))
                XCTAssertTrue(content.contains("Hi there! How can I help you?"))
                
                // Clean up
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to read exported file: \(error.localizedDescription)")
            }
        } else {
            XCTFail("Failed to export conversation")
        }
    }
    
    func testExportAsMarkdown() {
        // Create a conversation with messages
        let conversation = databaseManager.createConversation(title: "Test Conversation")
        
        // Add messages
        let message1 = Message(role: "user", content: "Hello")
        let message2 = Message(role: "assistant", content: "Hi there! How can I help you?")
        
        databaseManager.addMessage(message1, toConversation: conversation.id)
        databaseManager.addMessage(message2, toConversation: conversation.id)
        
        // Export as markdown
        if let fileURL = exporter.exportConversation(id: conversation.id, format: .markdown) {
            // Check that the file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            // Check the file content
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                
                // Verify the content contains the conversation title with markdown formatting
                XCTAssertTrue(content.contains("# Test Conversation"))
                
                // Verify the content contains the messages with markdown formatting
                XCTAssertTrue(content.contains("### You"))
                XCTAssertTrue(content.contains("### Assistant"))
                XCTAssertTrue(content.contains("Hello"))
                XCTAssertTrue(content.contains("Hi there! How can I help you?"))
                
                // Clean up
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to read exported file: \(error.localizedDescription)")
            }
        } else {
            XCTFail("Failed to export conversation")
        }
    }
    
    func testExportAsPDF() {
        // Create a conversation with messages
        let conversation = databaseManager.createConversation(title: "Test Conversation")
        
        // Add messages
        let message1 = Message(role: "user", content: "Hello")
        let message2 = Message(role: "assistant", content: "Hi there! How can I help you?")
        
        databaseManager.addMessage(message1, toConversation: conversation.id)
        databaseManager.addMessage(message2, toConversation: conversation.id)
        
        // Export as PDF
        if let fileURL = exporter.exportConversation(id: conversation.id, format: .pdf) {
            // Check that the file exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
            
            // Check the file size (should be non-zero)
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int {
                    XCTAssertGreaterThan(fileSize, 0)
                } else {
                    XCTFail("Failed to get file size")
                }
                
                // Clean up
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to check exported file: \(error.localizedDescription)")
            }
        } else {
            XCTFail("Failed to export conversation")
        }
    }
    
    func testExportNonExistentConversation() {
        // Try to export a conversation that doesn't exist
        let nonExistentId = "non-existent-id"
        let result = exporter.exportConversation(id: nonExistentId, format: .plainText)
        
        // Should return nil
        XCTAssertNil(result)
    }
}
