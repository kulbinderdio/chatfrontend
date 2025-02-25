import XCTest
@testable import MacOSChatApp

class DocumentHandlerTests: XCTestCase {
    
    var documentHandler: DocumentHandler!
    
    override func setUp() {
        super.setUp()
        documentHandler = DocumentHandler()
    }
    
    override func tearDown() {
        documentHandler = nil
        super.tearDown()
    }
    
    func testEstimateTokenCount() {
        // Given
        let text = String(repeating: "a", count: 400) // 400 characters
        
        // When
        let tokenCount = documentHandler.estimateTokenCount(for: text)
        
        // Then
        XCTAssertEqual(tokenCount, 100) // 400 characters ÷ 4 = 100 tokens
    }
    
    func testPreprocessText() {
        // Given
        let text = "Line 1\r\nLine 2\r\n\r\n\r\nLine 3   "
        
        // When
        let processedText = try? documentHandler.extractText(from: createTempFile(with: text))
        
        // Then
        XCTAssertEqual(processedText, "Line 1\nLine 2\n\nLine 3")
    }
    
    func testUnsupportedFileType() {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_image.jpg")
        
        // Create an empty file
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
        
        // When/Then
        XCTAssertThrowsError(try documentHandler.extractText(from: fileURL)) { error in
            XCTAssertEqual(error as? DocumentHandlerError, DocumentHandlerError.unsupportedFileType)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testEmptyDocument() {
        // Given
        let emptyFileURL = createTempFile(with: "")
        
        // When/Then
        XCTAssertThrowsError(try documentHandler.extractText(from: emptyFileURL)) { error in
            XCTAssertEqual(error as? DocumentHandlerError, DocumentHandlerError.fileReadError)
        }
    }
    
    // Helper method to create a temporary TXT file
    private func createTempFile(with content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("temp_test_file.txt")
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
