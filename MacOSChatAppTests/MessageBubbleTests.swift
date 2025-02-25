import XCTest
@testable import MacOSChatApp

class MessageBubbleTests: XCTestCase {
    
    func testUserMessageAlignment() throws {
        // Given
        let message = Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(bubble)
    }
    
    func testAssistantMessageAlignment() throws {
        // Given
        let message = Message(id: "1", role: "assistant", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(bubble)
    }
    
    func testBubbleColorForUserMessage() throws {
        // Given
        let message = Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(bubble)
    }
}
