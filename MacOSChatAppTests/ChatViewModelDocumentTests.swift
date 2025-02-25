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
        
        // When
        viewModel.handleDocumentDropped(url: url)
        
        // Then
        XCTAssertEqual(viewModel.extractedDocumentText, "Test document content")
        XCTAssertEqual(viewModel.extractedDocumentName, "test.pdf")
        XCTAssertTrue(viewModel.showExtractedTextEditor)
    }
    
    func testHandleDocumentError() {
        // Given
        let url = URL(fileURLWithPath: "/path/to/test.pdf")
        documentHandler.mockError = DocumentHandlerError.pdfProcessingError
        
        // When
        viewModel.handleDocumentDropped(url: url)
        
        // Then
        XCTAssertNil(viewModel.extractedDocumentText)
        XCTAssertNil(viewModel.extractedDocumentName)
        XCTAssertFalse(viewModel.showExtractedTextEditor)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Could not process the PDF file") ?? false)
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
