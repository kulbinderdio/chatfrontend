import XCTest
import Combine
@testable import MacOSChatApp

// Custom mock for DocumentHandler
class MockDocumentHandler: DocumentHandler {
    var mockExtractedText: String?
    var mockError: Error?
    
    override func extractText(from url: URL) throws -> String {
        if let error = mockError {
            throw error
        }
        
        return mockExtractedText ?? "Mock text"
    }
}

class ChatViewModelDocumentTests: XCTestCase {
    
    var viewModel: ChatViewModel!
    var documentHandler: MockDocumentHandler!
    var modelConfigManager: MockModelConfigurationManager!
    var databaseManager: MockDatabaseManager!
    var profileManager: MockProfileManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        let keychainManager = MockKeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        
        documentHandler = MockDocumentHandler()
        modelConfigManager = MockModelConfigurationManager(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        
        do {
            databaseManager = try MockDatabaseManager()
        } catch {
            XCTFail("Failed to initialize MockDatabaseManager: \(error)")
            return
        }
        
        profileManager = MockProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        viewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        documentHandler = nil
        modelConfigManager = nil
        databaseManager = nil
        profileManager = nil
        
        super.tearDown()
    }
    
    func testHandleDocumentDropped() {
        // Given
        let url = URL(fileURLWithPath: "/path/to/test.pdf")
        documentHandler.mockExtractedText = "Test document content"
        
        // Create an expectation
        let expectation = XCTestExpectation(description: "Document text extracted")
        
        // When
        viewModel.handleDocumentDropped(url: url)
        
        // Wait for async updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertEqual(self.viewModel.extractedDocumentText, "Test document content")
            XCTAssertEqual(self.viewModel.extractedDocumentName, "test.pdf")
            XCTAssertTrue(self.viewModel.showExtractedTextEditor)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandleDocumentError() {
        // Given
        let url = URL(fileURLWithPath: "/path/to/test.pdf")
        documentHandler.mockError = DocumentHandlerError.pdfProcessingError
        
        // Create an expectation
        let expectation = XCTestExpectation(description: "Document error handled")
        
        // When
        viewModel.handleDocumentDropped(url: url)
        
        // Wait for async updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertNil(self.viewModel.extractedDocumentText)
            XCTAssertNil(self.viewModel.extractedDocumentName)
            XCTAssertFalse(self.viewModel.showExtractedTextEditor)
            XCTAssertNotNil(self.viewModel.errorMessage)
            XCTAssertTrue(self.viewModel.errorMessage?.contains("Could not process the PDF file") ?? false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUseExtractedText() {
        // Given
        viewModel.extractedDocumentText = "Test document content"
        viewModel.extractedDocumentName = "test.pdf"
        viewModel.showExtractedTextEditor = true
        
        // When
        viewModel.useExtractedText()
        
        // Then
        XCTAssertNil(viewModel.extractedDocumentText)
        XCTAssertNil(viewModel.extractedDocumentName)
        XCTAssertFalse(viewModel.showExtractedTextEditor)
    }
    
    func testCancelExtractedText() {
        // Given
        viewModel.extractedDocumentText = "Test document content"
        viewModel.extractedDocumentName = "test.pdf"
        viewModel.showExtractedTextEditor = true
        
        // When
        viewModel.cancelExtractedText()
        
        // Then
        XCTAssertNil(viewModel.extractedDocumentText)
        XCTAssertNil(viewModel.extractedDocumentName)
        XCTAssertFalse(viewModel.showExtractedTextEditor)
    }
}
