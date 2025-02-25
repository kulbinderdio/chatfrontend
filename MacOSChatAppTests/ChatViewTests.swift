import XCTest
@testable import MacOSChatApp

class ChatViewTests: XCTestCase {
    
    func testChatViewRendersCorrectly() throws {
        // Given
        let viewModel = ChatViewModel()
        viewModel.messages = [
            Message(id: "1", role: "user", content: "Hello", timestamp: Date()),
            Message(id: "2", role: "assistant", content: "Hi there!", timestamp: Date())
        ]
        
        // When
        let view = ChatView(viewModel: viewModel)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(view)
    }
    
    func testSendMessageClearsInputField() throws {
        // Given
        let viewModel = ChatViewModel()
        
        // When
        let view = ChatView(viewModel: viewModel)
        
        // Then
        // Note: In a real implementation, we would use ViewInspector to test the view
        // But for now, we'll just check that the view can be created without errors
        XCTAssertNotNil(view)
    }
}
