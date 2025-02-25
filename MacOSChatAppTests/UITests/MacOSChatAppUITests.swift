import XCTest

class MacOSChatAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func testChatInterface() {
        // Open the chat window from menu bar
        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.exists)
        statusItem.click()
        
        // Verify chat interface elements
        let chatWindow = app.windows.firstMatch
        XCTAssertTrue(chatWindow.exists)
        
        let textEditor = chatWindow.textViews.firstMatch
        XCTAssertTrue(textEditor.exists)
        
        let sendButton = chatWindow.buttons["Send message"]
        XCTAssertTrue(sendButton.exists)
        XCTAssertFalse(sendButton.isEnabled) // Should be disabled when no text
        
        // Type a message
        textEditor.click()
        textEditor.typeText("Hello, assistant!")
        
        // Send button should be enabled now
        XCTAssertTrue(sendButton.isEnabled)
        sendButton.click()
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Wait for assistant response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
        
        // Verify message bubbles
        let messageBubbles = chatWindow.scrollViews.firstMatch.otherElements.matching(identifier: "MessageBubble")
        XCTAssertGreaterThanOrEqual(messageBubbles.count, 2) // At least user message and response
    }
    
    func testNewConversation() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Click new conversation button
        let newChatButton = app.buttons["New conversation"]
        XCTAssertTrue(newChatButton.exists)
        newChatButton.click()
        
        // Verify empty conversation
        let textEditor = app.textViews.firstMatch
        XCTAssertTrue(textEditor.exists)
        
        // No message bubbles should be present
        let messageBubbles = app.scrollViews.firstMatch.otherElements.matching(identifier: "MessageBubble")
        XCTAssertEqual(messageBubbles.count, 0)
    }
    
    func testConversationList() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Show conversation list
        let sidebarButton = app.buttons["Show conversation list"]
        XCTAssertTrue(sidebarButton.exists)
        sidebarButton.click()
        
        // Verify conversation list appears
        let conversationList = app.outlines.firstMatch
        XCTAssertTrue(conversationList.exists)
        
        // Create a new conversation
        let newChatButton = app.buttons["New conversation"]
        newChatButton.click()
        
        // Send a message to create conversation content
        let textEditor = app.textViews.firstMatch
        textEditor.click()
        textEditor.typeText("Test conversation")
        
        app.buttons["Send message"].click()
        
        // Wait for response
        let expectation = XCTestExpectation(description: "Wait for assistant response")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
        
        // Verify conversation appears in list
        XCTAssertGreaterThanOrEqual(conversationList.cells.count, 1)
    }
}
