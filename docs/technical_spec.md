# Technical Specification: MacOS AI Chat App

## 1. System Architecture

### 1.1 Overview
The MacOS AI Chat App is a native macOS application built using Swift and SwiftUI that provides a user-friendly interface for interacting with OpenAI-compatible language models. The application follows the Model-View-ViewModel (MVVM) architecture pattern to ensure separation of concerns and maintainability.

### 1.2 High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                      MacOS AI Chat App                       │
├─────────────┬─────────────────────────────┬─────────────────┤
│   UI Layer  │      Application Layer       │   Data Layer    │
│  (SwiftUI)  │     (Business Logic)         │  (Persistence)  │
├─────────────┼─────────────────────────────┼─────────────────┤
│ - Chat View │ - Chat View Model            │ - SQLite DB     │
│ - Settings  │ - Document Handler           │ - Keychain      │
│ - Profiles  │ - API Client                 │ - UserDefaults  │
│ - Menu Bar  │ - Model Configuration        │ - File I/O      │
└─────────────┴─────────────────────────────┴─────────────────┘
```

### 1.3 Component Breakdown

#### 1.3.1 UI Layer
- **ChatView**: Main conversation interface with message bubbles, input field, and send button
- **SettingsView**: Configuration interface for API keys, model parameters, and preferences
- **ProfilesView**: Interface for managing and selecting different model profiles
- **MenuBarComponent**: System tray icon and menu for quick access
- **DocumentDropArea**: UI component that handles drag-and-drop functionality for files

#### 1.3.2 Application Layer
- **ChatViewModel**: Manages chat state, message history, and conversation context
- **DocumentHandler**: Processes PDF and TXT files, extracting text content
- **APIClient**: Handles communication with OpenAI-compatible endpoints
- **ModelConfigurationManager**: Manages model settings and parameters
- **ProfileManager**: Handles creation, storage, and selection of model profiles

#### 1.3.3 Data Layer
- **DatabaseManager**: Handles local SQLite storage for conversation history
- **KeychainManager**: Securely stores API keys in macOS Keychain
- **UserDefaultsManager**: Stores user preferences and settings
- **FileManager**: Handles file system operations for document processing and exports

## 2. Dependencies and Libraries

### 2.1 Core Dependencies
| Library/Framework | Version | Purpose |
|-------------------|---------|---------|
| Swift | 5.9+ | Primary programming language |
| SwiftUI | macOS 13.0+ | UI framework |
| Combine | Built-in | Reactive programming |
| Foundation | Built-in | Core functionality |
| AppKit | Built-in | macOS-specific functionality |

### 2.2 Third-Party Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| SQLite.swift | 0.14.1 | SQLite database interface |
| PDFKit | Built-in | PDF processing and text extraction |
| KeychainAccess | 4.2.2 | Simplified Keychain API |
| Alamofire | 5.8.0 | HTTP networking |
| SwiftyJSON | 5.0.1 | JSON parsing |
| MarkdownKit | 1.7.1 | Markdown rendering for chat messages |

## 3. UI/UX Design Specification

### 3.1 Design Principles
- **Native macOS Feel**: Adhere to Apple's Human Interface Guidelines
- **Minimalist Design**: Clean, uncluttered interface with focus on content
- **Responsive Layout**: Adapts to different window sizes
- **Accessibility**: Support for VoiceOver and other accessibility features
- **Dark Mode Support**: Seamless transition between light and dark themes

### 3.2 Chat Interface Design
- **Message Bubbles**:
  - User messages: Right-aligned, blue background (#007AFF)
  - AI responses: Left-aligned, gray background (#E9E9EB in light mode, #3A3A3C in dark mode)
  - Rounded corners (10pt radius)
  - Padding: 12pt horizontal, 8pt vertical
  - Font: System font, 13pt
  
- **Input Area**:
  - Multi-line text field with auto-expansion
  - Send button with paper airplane icon
  - File attachment button with paperclip icon
  - Placeholder text: "Type a message..."
  - Bottom-aligned, full width
  - Light background with subtle border

- **Conversation History**:
  - Scrollable area with momentum scrolling
  - Date separators between conversations
  - Timestamp display for messages (configurable)
  - Unread message indicator

### 3.3 Menu Bar Integration
- **Icon**: Simple chat bubble icon (template image for automatic light/dark adaptation)
- **Menu Items**:
  - New Chat
  - Show/Hide Window
  - Profile Selection submenu
  - Settings
  - Quit

### 3.4 Settings Panel
- **Tabbed Interface**:
  - API Configuration
  - Model Settings
  - Profiles
  - Appearance
  - Advanced

- **Form Controls**:
  - Sliders for numerical parameters
  - Toggle switches for boolean options
  - Dropdown menus for selections
  - Text fields for API keys and URLs

### 3.5 Profile Management UI
- **Profile List**:
  - Name and model type display
  - Selection indicator
  - Edit and delete buttons
  
- **Profile Editor**:
  - Form for name, API URL, API key, and model parameters
  - Save and cancel buttons
  - Test connection functionality

## 4. Profile Management

### 4.1 Profile Data Structure
```swift
struct ModelProfile {
    let id: UUID
    var name: String
    var apiEndpoint: URL
    var apiKey: String // Reference to Keychain item
    var modelName: String
    var parameters: ModelParameters
    var isDefault: Bool
}

struct ModelParameters {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
}
```

### 4.2 Profile Storage
- Profiles metadata stored in SQLite database
- API keys stored securely in Keychain with reference IDs
- Default profile marked in database

### 4.3 Profile Selection
- Available in menu bar dropdown
- Available in settings panel
- Persists between app launches
- Quick switching during active conversations

### 4.4 Profile Management Features
- Create new profiles
- Edit existing profiles
- Delete profiles (with confirmation)
- Duplicate profiles
- Import/export profiles (JSON format)
- Test connection to verify API endpoint and key

## 5. Implementation Details

### 5.1 Chat Functionality
- **Message Processing**:
  - Messages stored as structured data with metadata
  - Support for markdown formatting in AI responses
  - Code block syntax highlighting
  - Message retry capability
  - Context window management to prevent token limit issues

- **Conversation Management**:
  - Automatic conversation splitting based on time or topic
  - Conversation naming and organization
  - Search functionality across all conversations
  - Conversation export (TXT, MD, PDF formats)

### 5.2 Document Handling
- **Supported Formats**:
  - PDF: Using PDFKit for text extraction
  - TXT: Direct text reading with encoding detection
  
- **Processing Pipeline**:
  1. File dropped or selected
  2. File type detection
  3. Text extraction based on file type
  4. Text preprocessing (whitespace normalization, etc.)
  5. Display in editable text area for user review
  6. Inclusion in prompt upon confirmation

- **Large Document Handling**:
  - Warning for very large documents
  - Option to truncate to fit token limits
  - Visual indicator of approximate token count

### 5.3 API Integration
- **Request Format**:
```json
{
  "model": "gpt-4",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello, world!"}
  ],
  "temperature": 0.7,
  "max_tokens": 2048,
  "top_p": 1.0,
  "frequency_penalty": 0.0,
  "presence_penalty": 0.0
}
```

- **Response Handling**:
  - Streaming support for real-time responses
  - Error handling with user-friendly messages
  - Retry mechanism for failed requests
  - Rate limiting awareness

- **Ollama Integration**:
  - Support for local Ollama endpoint
  - Model availability detection
  - Parameter mapping between OpenAI and Ollama formats

### 5.4 Data Storage
- **SQLite Schema**:
```sql
CREATE TABLE conversations (
    id TEXT PRIMARY KEY,
    title TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    profile_id TEXT,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);

CREATE TABLE messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT,
    role TEXT,
    content TEXT,
    timestamp TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id)
);

CREATE TABLE profiles (
    id TEXT PRIMARY KEY,
    name TEXT,
    api_endpoint TEXT,
    keychain_reference TEXT,
    model_name TEXT,
    temperature REAL,
    max_tokens INTEGER,
    top_p REAL,
    frequency_penalty REAL,
    presence_penalty REAL,
    is_default INTEGER
);
```

- **Keychain Usage**:
  - Service name: "com.app.macoschatapp"
  - Account format: "api-key-{profile_id}"
  - Access control: kSecAccessControlUserPresence

### 5.5 Security Considerations
- API keys never stored in plain text
- No external network requests except to configured API endpoints
- Local-only data storage
- Secure deletion of sensitive data
- Optional conversation auto-deletion after configurable time period

## 6. Build and Deployment

### 6.1 Development Environment
- **Requirements**:
  - macOS 13.0 or later
  - Xcode 15.0 or later
  - Swift 5.9 or later
  - CocoaPods or Swift Package Manager for dependency management

### 6.2 Build Process
1. **Clone Repository**:
   ```bash
   git clone https://github.com/yourusername/macoschatapp.git
   cd macoschatapp
   ```

2. **Install Dependencies**:
   ```bash
   # Using Swift Package Manager
   xcodebuild -resolvePackageDependencies
   
   # Or using CocoaPods
   pod install
   ```

3. **Build Application**:
   ```bash
   xcodebuild -scheme "MacOSChatApp" -configuration Release
   ```

4. **Run Application**:
   ```bash
   open ./build/Release/MacOSChatApp.app
   ```

### 6.3 Distribution
- **Notarization**:
  - Code signing with Developer ID
  - Submission to Apple notary service
  - Stapling ticket to application

- **DMG Creation**:
  1. Create background image
  2. Set up DMG layout with application and Applications folder symlink
  3. Create DMG with create-dmg tool
  4. Sign and notarize DMG

- **App Store Distribution** (Optional):
  - Prepare App Store Connect listing
  - Configure app for sandbox environment
  - Submit for review

### 6.4 Updates
- **In-App Updates**:
  - Version checking against GitHub releases or custom endpoint
  - Download and installation of updates
  - Release notes display

## 7. Testing Strategy

### 7.1 Testing Frameworks
- **XCTest**: Core testing framework
- **XCUITest**: UI testing
- **Quick & Nimble**: BDD-style testing
- **OHHTTPStubs**: Network request stubbing

### 7.2 Test Categories

#### 7.2.1 Unit Tests
- **Coverage Target**: 80% code coverage
- **Focus Areas**:
  - API client
  - Document processing
  - Data persistence
  - Model configuration
  - Profile management

#### 7.2.2 Integration Tests
- API integration with mock server
- Database operations
- Keychain interactions
- File system operations

#### 7.2.3 UI Tests
- Chat interaction flow
- Settings configuration
- Profile management
- Document drag and drop
- Accessibility compliance

### 7.3 Test Automation
- CI/CD pipeline with GitHub Actions
- Automated test runs on pull requests
- Code coverage reporting
- Linting with SwiftLint

## 8. Unit Test Details

### 8.1 ChatViewModel Tests
- Test conversation initialization
- Test message addition and retrieval
- Test context window management
- Test conversation export functionality
- Test search functionality

```swift
func testMessageAddition() {
    // Given
    let viewModel = ChatViewModel()
    let initialCount = viewModel.messages.count
    
    // When
    viewModel.addMessage(role: .user, content: "Test message")
    
    // Then
    XCTAssertEqual(viewModel.messages.count, initialCount + 1)
    XCTAssertEqual(viewModel.messages.last?.role, .user)
    XCTAssertEqual(viewModel.messages.last?.content, "Test message")
}
```

### 8.2 DocumentHandler Tests
- Test PDF text extraction
- Test TXT file reading
- Test large file handling
- Test error conditions (corrupted files, etc.)

```swift
func testPDFTextExtraction() {
    // Given
    let documentHandler = DocumentHandler()
    let testPDFURL = Bundle(for: type(of: self)).url(forResource: "test", withExtension: "pdf")!
    
    // When
    let extractedText = try? documentHandler.extractText(from: testPDFURL)
    
    // Then
    XCTAssertNotNil(extractedText)
    XCTAssertTrue(extractedText!.contains("Expected content"))
}
```

### 8.3 APIClient Tests
- Test request formation
- Test response parsing
- Test error handling
- Test retry mechanism
- Test streaming responses

```swift
func testAPIRequestFormation() {
    // Given
    let apiClient = APIClient(endpoint: URL(string: "https://api.example.com")!, apiKey: "test-key")
    let messages = [Message(role: .user, content: "Hello")]
    let parameters = ModelParameters(temperature: 0.7, maxTokens: 100, topP: 1.0, frequencyPenalty: 0.0, presencePenalty: 0.0)
    
    // When
    let request = apiClient.createRequest(messages: messages, parameters: parameters)
    
    // Then
    XCTAssertEqual(request.url?.absoluteString, "https://api.example.com")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertTrue(request.allHTTPHeaderFields?["Authorization"]?.contains("Bearer test-key") ?? false)
    
    // Verify request body contains correct data
    let requestBody = try? JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]
    XCTAssertNotNil(requestBody)
    XCTAssertEqual(requestBody?["temperature"] as? Double, 0.7)
    XCTAssertEqual(requestBody?["max_tokens"] as? Int, 100)
}
```

### 8.4 DatabaseManager Tests
- Test conversation storage and retrieval
- Test message persistence
- Test profile management
- Test database migrations

```swift
func testConversationStorage() {
    // Given
    let dbManager = DatabaseManager()
    let conversationId = UUID().uuidString
    let title = "Test Conversation"
    
    // When
    try? dbManager.createConversation(id: conversationId, title: title)
    let retrievedConversation = dbManager.getConversation(id: conversationId)
    
    // Then
    XCTAssertNotNil(retrievedConversation)
    XCTAssertEqual(retrievedConversation?.title, title)
}
```

### 8.5 ProfileManager Tests
- Test profile creation and retrieval
- Test default profile selection
- Test profile updating
- Test profile deletion
- Test import/export functionality

```swift
func testProfileCreation() {
    // Given
    let profileManager = ProfileManager()
    let profileName = "Test Profile"
    let endpoint = URL(string: "https://api.example.com")!
    
    // When
    let profile = try? profileManager.createProfile(name: profileName, apiEndpoint: endpoint, apiKey: "test-key", modelName: "gpt-4")
    
    // Then
    XCTAssertNotNil(profile)
    XCTAssertEqual(profile?.name, profileName)
    XCTAssertEqual(profile?.apiEndpoint, endpoint)
    
    // Verify the profile was stored
    let retrievedProfile = profileManager.getProfile(id: profile!.id)
    XCTAssertNotNil(retrievedProfile)
}
```

## 9. Performance Considerations

### 9.1 Memory Management
- Efficient handling of large conversations
- Pagination of conversation history
- Image and resource caching
- Memory usage monitoring

### 9.2 Responsiveness
- Background processing for document handling
- Asynchronous API requests
- UI updates on main thread
- Progress indicators for long-running operations

### 9.3 Battery Impact
- Efficient network usage
- Background task optimization
- Power usage monitoring

## 10. Accessibility

### 10.1 VoiceOver Support
- Proper labeling of UI elements
- Logical navigation flow
- Descriptive announcements

### 10.2 Keyboard Navigation
- Full keyboard control
- Keyboard shortcuts for common actions
- Focus indicators

### 10.3 Dynamic Type
- Support for system font size adjustments
- Layout adaptation for larger text sizes

## 11. Localization

### 11.1 Supported Languages
- English (default)
- Future expansion to other languages

### 11.2 Localization Strategy
- String tables for all user-facing text
- Date and number formatting based on locale
- RTL language support

## 12. Maintenance and Support

### 12.1 Logging
- Tiered logging levels (debug, info, warning, error)
- Optional diagnostic logging
- Privacy-conscious log content

### 12.2 Error Handling
- User-friendly error messages
- Detailed developer logs
- Crash reporting (optional, with user consent)

### 12.3 Documentation
- Code documentation with DocC
- User manual
- Developer guide for contributors

---

This technical specification serves as the blueprint for development of the MacOS AI Chat App. It provides comprehensive details on implementation, testing, and deployment to ensure a high-quality, maintainable application.
