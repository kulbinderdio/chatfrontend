import XCTest

class DocumentHandlingUITests: XCTestCase {
    
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
    
    func testFileAttachment() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Click attachment button
        let attachButton = app.buttons["Attach a file"]
        XCTAssertTrue(attachButton.exists)
        attachButton.click()
        
        // File picker should appear
        let filePicker = app.sheets.firstMatch
        XCTAssertTrue(filePicker.exists)
        
        // Note: We can't fully test file selection in UI tests
        // as it involves system dialogs, but we can verify the picker appears
        
        // Cancel the file picker
        let cancelButton = filePicker.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.click()
        }
    }
    
    func testDocumentDropAreaVisibility() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Verify the document drop area exists
        let textEditor = app.textViews.firstMatch
        XCTAssertTrue(textEditor.exists)
        
        // The document drop area should be accessible
        let dropArea = app.otherElements["Document drop area"]
        XCTAssertTrue(dropArea.exists)
    }
    
    func testKeyboardShortcuts() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Test keyboard shortcut for file attachment (Cmd+D)
        app.typeKey("d", modifierFlags: .command)
        
        // File picker should appear
        let filePicker = app.sheets.firstMatch
        XCTAssertTrue(filePicker.exists)
        
        // Cancel the file picker
        let cancelButton = filePicker.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.click()
        }
    }
    
    func testAccessibilityLabels() {
        // Open the chat window
        app.statusItems.firstMatch.click()
        
        // Verify accessibility labels are set correctly
        let dropArea = app.otherElements["Document drop area"]
        XCTAssertTrue(dropArea.exists)
        
        let messageInput = app.textViews["Message input"]
        XCTAssertTrue(messageInput.exists)
        
        let attachButton = app.buttons["Attach a file"]
        XCTAssertTrue(attachButton.exists)
    }
}
