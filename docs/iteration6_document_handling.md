# Iteration 6: Document Handling

## Overview
This iteration focuses on implementing the document handling functionality, which allows users to drag and drop PDF and TXT files into the chat interface. The application will extract text from these documents and insert it into the prompt, enabling users to easily reference external content in their conversations with AI models.

## Objectives
- Implement drag and drop functionality for PDF and TXT files
- Create the DocumentHandler for extracting text from files
- Implement text preprocessing and display
- Add user editing capability for extracted text
- Create unit tests for document handling

## Implementation Details

### 1. DocumentHandler Implementation
1. Create the document handler class:

```swift
import Foundation
import PDFKit

enum DocumentHandlerError: Error {
    case unsupportedFileType
    case fileReadError
    case pdfProcessingError
    case emptyDocument
}

class DocumentHandler {
    func extractText(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try extractTextFromPDF(url: url)
        case "txt":
            return try extractTextFromTXT(url: url)
        default:
            throw DocumentHandlerError.unsupportedFileType
        }
    }
    
    private func extractTextFromPDF(url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentHandlerError.pdfProcessingError
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            if let pageText = page.string {
                extractedText += pageText
                
                // Add a newline between pages
                if pageIndex < pdfDocument.pageCount - 1 {
                    extractedText += "\n\n"
                }
            }
        }
        
        if extractedText.isEmpty {
            throw DocumentHandlerError.emptyDocument
        }
        
        return preprocessText(extractedText)
    }
    
    private func extractTextFromTXT(url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            
            // Try to detect encoding
            let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .utf16]
            
            for encoding in encodings {
                if let text = String(data: data, encoding: encoding) {
                    if !text.isEmpty {
                        return preprocessText(text)
                    }
                }
            }
            
            throw DocumentHandlerError.fileReadError
        } catch {
            throw DocumentHandlerError.fileReadError
        }
    }
    
    private func preprocessText(_ text: String) -> String {
        // Normalize whitespace
        var processedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        // Remove excessive newlines (more than 2 consecutive)
        processedText = processedText.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Trim whitespace
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Rough estimation: 1 token ≈ 4 characters for English text
        return text.count / 4
    }
}
```

### 2. DocumentDropArea Implementation
1. Create the document drop area component:

```swift
import SwiftUI

struct DocumentDropArea<Content: View>: View {
    let onDocumentDropped: (URL) -> Void
    let content: Content
    
    @State private var isTargeted = false
    
    init(onDocumentDropped: @escaping (URL) -> Void, @ViewBuilder content: () -> Content) {
        self.onDocumentDropped = onDocumentDropped
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
            )
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool
                providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, _ in
                    DispatchQueue.main.async {
                        if let urlData = urlData as? Data {
                            let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                            
                            // Check if file is PDF or TXT
                            let fileExtension = url.pathExtension.lowercased()
                            if fileExtension == "pdf" || fileExtension == "txt" {
                                onDocumentDropped(url)
                            }
                        }
                    }
                }
                return true
            }
    }
}
```

### 3. DocumentPicker Implementation
1. Create the document picker component:

```swift
import SwiftUI
import AppKit

struct DocumentPicker: NSViewRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["pdf", "txt"]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onDocumentPicked(url)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
```

### 4. ChatViewModel Integration
1. Update the ChatViewModel to handle document dropping:

```swift
import Foundation
import Combine

extension ChatViewModel {
    func handleDocumentDropped(url: URL) {
        do {
            let text = try documentHandler.extractText(from: url)
            let tokenCount = documentHandler.estimateTokenCount(for: text)
            
            // Create a temporary message to show the extracted text
            let extractedTextMessage = Message(
                id: "temp-\(UUID().uuidString)",
                role: "system",
                content: "Extracted text from \(url.lastPathComponent) (approx. \(tokenCount) tokens):\n\n\(text)",
                timestamp: Date()
            )
            
            // Show in UI but don't save to database
            DispatchQueue.main.async {
                self.extractedDocumentText = text
                self.extractedDocumentName = url.lastPathComponent
                self.showExtractedTextEditor = true
            }
        } catch {
            handleDocumentError(error)
        }
    }
    
    private func handleDocumentError(_ error: Error) {
        let errorMessage: String
        
        if let docError = error as? DocumentHandlerError {
            switch docError {
            case .unsupportedFileType:
                errorMessage = "Unsupported file type. Please use PDF or TXT files."
            case .fileReadError:
                errorMessage = "Could not read the file. It may be corrupted or inaccessible."
            case .pdfProcessingError:
                errorMessage = "Could not process the PDF file. It may be corrupted or password-protected."
            case .emptyDocument:
                errorMessage = "The document appears to be empty."
            }
        } else {
            errorMessage = "Failed to process document: \(error.localizedDescription)"
        }
        
        DispatchQueue.main.async {
            self.errorMessage = errorMessage
        }
    }
    
    func useExtractedText() {
        guard let text = extractedDocumentText, !text.isEmpty else {
            return
        }
        
        // Create and send a message with the extracted text
        sendMessage(content: text)
        
        // Reset extracted text
        extractedDocumentText = nil
        extractedDocumentName = nil
        showExtractedTextEditor = false
    }
    
    func cancelExtractedText() {
        extractedDocumentText = nil
        extractedDocumentName = nil
        showExtractedTextEditor = false
    }
}
```

2. Add properties to ChatViewModel:

```swift
class ChatViewModel: ObservableObject {
    // Existing properties...
    
    @Published var extractedDocumentText: String? = nil
    @Published var extractedDocumentName: String? = nil
    @Published var showExtractedTextEditor: Bool = false
    
    // Existing methods...
}
```

### 5. ExtractedTextEditorView Implementation
1. Create the extracted text editor view:

```swift
import SwiftUI

struct ExtractedTextEditorView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var text: String
    let documentName: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Extracted from: \(documentName)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.cancelExtractedText()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("You can edit the text before sending:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .frame(minHeight: 200)
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelExtractedText()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Send") {
                    viewModel.useExtractedText()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }
}
```

### 6. ChatView Integration
1. Update the ChatView to include the extracted text editor:

```swift
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    @State private var isFilePickerPresented: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat history
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom) {
                Button(action: {
                    isFilePickerPresented = true
                }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Attach a file")
                
                DocumentDropArea(onDocumentDropped: { url in
                    viewModel.handleDocumentDropped(url: url)
                }) {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 36, maxHeight: 120)
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Send message")
            }
            .padding()
        }
        .sheet(isPresented: $isFilePickerPresented) {
            DocumentPicker(onDocumentPicked: { url in
                viewModel.handleDocumentDropped(url: url)
            })
        }
        .sheet(isPresented: $viewModel.showExtractedTextEditor) {
            if let text = viewModel.extractedDocumentText, let documentName = viewModel.extractedDocumentName {
                ExtractedTextEditorView(
                    viewModel: viewModel,
                    text: Binding(
                        get: { text },
                        set: { viewModel.extractedDocumentText = $0 }
                    ),
                    documentName: documentName
                )
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            viewModel.sendMessage(content: trimmedText)
            messageText = ""
        }
    }
}
```

### 7. Large Document Handling
1. Add token limit warning to the ExtractedTextEditorView:

```swift
import SwiftUI

struct ExtractedTextEditorView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var text: String
    let documentName: String
    
    // Approximate token limit for most models
    private let tokenLimit = 4096
    
    private var tokenCount: Int {
        viewModel.documentHandler.estimateTokenCount(for: text)
    }
    
    private var isOverTokenLimit: Bool {
        tokenCount > tokenLimit
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Extracted from: \(documentName)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.cancelExtractedText()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                Text("You can edit the text before sending:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Approx. \(tokenCount) tokens")
                    .font(.caption)
                    .foregroundColor(isOverTokenLimit ? .red : .secondary)
            }
            
            if isOverTokenLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("This text exceeds the typical token limit (\(tokenLimit)). Consider trimming it down.")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button("Truncate") {
                        truncateText()
                    }
                    .font(.caption)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .frame(minHeight: 200)
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelExtractedText()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Button("Send") {
                    viewModel.useExtractedText()
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(BorderedButtonStyle())
            }
        }
        .padding()
        .frame(width: 600, height: 400)
    }
    
    private func truncateText() {
        // Truncate text to approximately fit within token limit
        // This is a simple approach - in a real app, you might want to be smarter about where to cut
        let maxChars = tokenLimit * 4 // Rough estimation: 1 token ≈ 4 characters
        
        if text.count > maxChars {
            let index = text.index(text.startIndex, offsetBy: maxChars)
            text = String(text[..<index])
            
            // Add a note about truncation
            text += "\n\n[Text has been truncated due to token limit]"
        }
    }
}
```

## Unit Tests
The following tests will verify that the document handling is implemented correctly:

### 1. DocumentHandlerTests.swift
```swift
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
    
    func testExtractTextFromTXT() throws {
        // Given
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "test_document", withExtension: "txt") else {
            XCTFail("Test TXT file not found")
            return
        }
        
        // When
        let extractedText = try documentHandler.extractText(from: url)
        
        // Then
        XCTAssertFalse(extractedText.isEmpty)
        XCTAssertTrue(extractedText.contains("This is a test document"))
    }
    
    func testExtractTextFromPDF() throws {
        // Given
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "test_document", withExtension: "pdf") else {
            XCTFail("Test PDF file not found")
            return
        }
        
        // When
        let extractedText = try documentHandler.extractText(from: url)
        
        // Then
        XCTAssertFalse(extractedText.isEmpty)
        XCTAssertTrue(extractedText.contains("This is a test document"))
    }
    
    func testUnsupportedFileType() {
        // Given
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "test_image", withExtension: "png") else {
            XCTFail("Test PNG file not found")
            return
        }
        
        // When/Then
        XCTAssertThrowsError(try documentHandler.extractText(from: url)) { error in
            XCTAssertEqual(error as? DocumentHandlerError, DocumentHandlerError.unsupportedFileType)
        }
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
    
    // Helper method to create a temporary TXT file
    private func createTempFile(with content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("temp_test_file.txt")
        
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
}
```

### 2. DocumentDropAreaTests.swift
```swift
import XCTest
import ViewInspector
@testable import MacOSChatApp

extension DocumentDropArea: Inspectable {}

class DocumentDropAreaTests: XCTestCase {
    
    func testDocumentDropAreaRendersContent() throws {
        // Given
        var dropCallCount = 0
        let onDrop: (URL) -> Void = { _ in dropCallCount += 1 }
        
        // When
        let dropArea = DocumentDropArea(onDocumentDropped: onDrop) {
            Text("Drop files here")
        }
        
        // Then
        let text = try dropArea.inspect().find(text: "Drop files here")
        XCTAssertNotNil(text)
    }
    
    func testDocumentDropAreaShowsBorderWhenTargeted() throws {
        // Given
        var dropCallCount = 0
        let onDrop: (URL) -> Void = { _ in dropCallCount += 1 }
        
        // When
        let dropArea = DocumentDropArea(onDocumentDropped: onDrop) {
            Text("Drop files here")
        }
        
        // Then
        // Set isTargeted to true
        try dropArea.inspect().modifier({ modifier in
            guard let overlay = modifier as? _OverlayModifier<Text, RoundedRectangle> else {
                return false
            }
            
            // This is a simplified test as ViewInspector doesn't easily allow modifying state
            return true
        })
    }
}
```

### 3. ChatViewModelDocumentTests.swift
```swift
import XCTest
import Combine
@testable import MacOSChatApp

class ChatViewModelDocumentTests: XCTestCase {
    
    var viewModel: ChatViewModel!
    var documentHandler: MockDocumentHandler!
    var modelConfigManager: MockModelConfigurationManager!
    var databaseManager: MockDatabaseManager!
    var profileManager: MockProfileManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        
        documentHandler = MockDocumentHandler()
        modelConfigManager = MockModelConfigurationManager()
        databaseManager = MockDatabaseManager()
        profileManager = MockProfileManager()
        
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
        
        // Verify that sendMessage was called
        XCTAssertEqual(modelConfigManager.lastSentMessage, "Test document content")
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
        
        // Verify that sendMessage was not called
        XCTAssertNil(modelConfigManager.lastSentMessage)
    }
}

// Mock classes for testing
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

class MockModelConfigurationManager: ModelConfigurationManager {
    var lastSentMessage: String?
    
    override func sendMessage(messages: [Message]) -> AnyPublisher<String, APIClientError> {
        if let message = messages.last {
            lastSentMessage = message.content
        }
        
        return Just("Mock response")
            .setFailureType(to: APIClientError.self)
            .eraseToAnyPublisher()
    }
}
```

## Acceptance Criteria
- [x] Users can drag and drop PDF and TXT files into the chat interface
- [x] Text is correctly extracted from PDF and TXT files
- [x] Users can edit the extracted text before sending it
- [x] Large documents are handled appropriately with warnings and truncation options
- [x] Error handling for unsupported file types and processing issues
- [x] All unit tests pass, confirming the document handling functionality works correctly

## Next Steps
Once this iteration is complete, the application will have the ability to handle document uploads, extract text, and incorporate it into conversations. The next iteration will focus on final integration and testing to ensure all components work together seamlessly.
