# Iteration 7: Final Integration & Testing

## Overview
This iteration focuses on integrating all components of the application, performing comprehensive testing, implementing final UI refinements, and preparing the application for deployment. This ensures that all features work together seamlessly and the application provides a polished user experience.

## Objectives
- Integrate all components of the application
- Implement UI tests to verify end-to-end functionality
- Add accessibility features
- Optimize performance
- Prepare for deployment
- Create documentation

## Implementation Details

### 1. Final Integration
1. Update the main app file to integrate all components:

```swift
import SwiftUI

@main
struct MacOSChatApp: App {
    // Create managers and handlers
    private let keychainManager = KeychainManager()
    private let documentHandler = DocumentHandler()
    
    // Use StateObject for view models that need to persist throughout the app lifecycle
    @StateObject private var databaseManager: DatabaseManager
    @StateObject private var profileManager: ProfileManager
    @StateObject private var modelConfigManager: ModelConfigurationManager
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var conversationListViewModel: ConversationListViewModel
    
    // Menu bar manager
    private let menuBarManager = MenuBarManager()
    
    init() {
        // Initialize database manager
        let dbManager: DatabaseManager
        do {
            dbManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize database: \(error.localizedDescription)")
        }
        _databaseManager = StateObject(wrappedValue: dbManager)
        
        // Initialize profile manager
        let profileMgr = ProfileManager(databaseManager: dbManager, keychainManager: keychainManager)
        _profileManager = StateObject(wrappedValue: profileMgr)
        
        // Initialize model configuration manager
        let modelConfigMgr = ModelConfigurationManager(keychainManager: keychainManager)
        _modelConfigManager = StateObject(wrappedValue: modelConfigMgr)
        
        // Initialize conversation list view model
        let exporter = ConversationExporter(databaseManager: dbManager)
        let convListViewModel = ConversationListViewModel(databaseManager: dbManager, exporter: exporter)
        _conversationListViewModel = StateObject(wrappedValue: convListViewModel)
        
        // Initialize chat view model
        let chatVM = ChatViewModel(
            modelConfigManager: modelConfigMgr,
            databaseManager: dbManager,
            documentHandler: documentHandler,
            profileManager: profileMgr
        )
        _chatViewModel = StateObject(wrappedValue: chatVM)
    }
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .onAppear {
                    setupMenuBar()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView(
                profileManager: profileManager,
                modelConfigManager: modelConfigManager
            )
        }
    }
    
    private func setupMenuBar() {
        let chatView = ChatView(
            viewModel: chatViewModel,
            conversationListViewModel: conversationListViewModel
        )
        
        menuBarManager.setupMenuBar(with: chatView)
    }
}
```

2. Update the MenuBarManager to include conversation management:

```swift
import SwiftUI
import AppKit

class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    
    func setupMenuBar(with rootView: ChatView) {
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 800, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: rootView)
        self.popover = popover
        
        // Create the status item
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "Chat")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        self.statusItem = statusItem
        
        // Create event monitor to detect clicks outside the popover
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let popover = self.popover else { return }
            
            if popover.isShown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        
        // Set up menu
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "New Chat", action: #selector(newChat), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            closePopover(sender)
        } else {
            statusItem?.menu = nil
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func newChat() {
        // Post notification to create new chat
        NotificationCenter.default.post(name: Notification.Name("NewChatRequested"), object: nil)
        
        // Show popover
        if let button = statusItem?.button, let popover = popover, !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        setupMenu()
    }
}
```

3. Update the ChatView to include conversation list:

```swift
import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var conversationListViewModel: ConversationListViewModel
    @State private var messageText: String = ""
    @State private var isFilePickerPresented: Bool = false
    @State private var showConversationList: Bool = false
    
    var body: some View {
        NavigationView {
            if showConversationList {
                // Conversation list sidebar
                ConversationListView(viewModel: conversationListViewModel)
                    .frame(minWidth: 250)
            }
            
            // Chat area
            VStack(spacing: 0) {
                // Chat header
                HStack {
                    Button(action: {
                        withAnimation {
                            showConversationList.toggle()
                        }
                    }) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help(showConversationList ? "Hide conversation list" : "Show conversation list")
                    
                    Text(conversationListViewModel.currentConversationTitle ?? "New Conversation")
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        createNewConversation()
                    }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help("New conversation")
                }
                .padding()
                .background(Color(.windowBackgroundColor))
                
                Divider()
                
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
                
                // Loading indicator
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.vertical, 8)
                        Spacer()
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
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .help("Send message")
                }
                .padding()
            }
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
        .onAppear {
            // Load current conversation
            if let conversationId = conversationListViewModel.currentConversationId {
                viewModel.loadConversation(id: conversationId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewChatRequested"))) { _ in
            createNewConversation()
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty && !viewModel.isLoading {
            viewModel.sendMessage(content: trimmedText)
            messageText = ""
        }
    }
    
    private func createNewConversation() {
        if let newConversationId = conversationListViewModel.createNewConversation() {
            viewModel.loadConversation(id: newConversationId)
        }
    }
}
```

4. Create the ConversationListView:

```swift
import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    @State private var searchText: String = ""
    @State private var isEditingTitle: Bool = false
    @State private var editingConversationId: String? = nil
    @State private var newTitle: String = ""
    @State private var showingExportOptions: Bool = false
    @State private var conversationToExport: Conversation? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search conversations", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { newValue in
                        viewModel.searchQuery = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .padding([.horizontal, .top])
            
            // Conversation list
            List {
                ForEach(viewModel.filteredConversations) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isSelected: viewModel.currentConversationId == conversation.id,
                        isEditing: editingConversationId == conversation.id,
                        newTitle: $newTitle,
                        onSelect: {
                            viewModel.selectConversation(id: conversation.id)
                        },
                        onDelete: {
                            viewModel.deleteConversation(id: conversation.id)
                        },
                        onStartEditing: {
                            editingConversationId = conversation.id
                            newTitle = conversation.title
                        },
                        onSaveEditing: {
                            viewModel.updateConversationTitle(id: conversation.id, title: newTitle)
                            editingConversationId = nil
                        },
                        onCancelEditing: {
                            editingConversationId = nil
                        },
                        onExport: {
                            conversationToExport = conversation
                            showingExportOptions = true
                        }
                    )
                }
            }
            .listStyle(SidebarListStyle())
            
            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.vertical, 8)
            }
        }
        .popover(isPresented: $showingExportOptions) {
            if let conversation = conversationToExport {
                ExportOptionsView(
                    viewModel: viewModel,
                    conversation: conversation
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
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let isEditing: Bool
    @Binding var newTitle: String
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onStartEditing: () -> Void
    let onSaveEditing: () -> Void
    let onCancelEditing: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Conversation title", text: $newTitle, onCommit: onSaveEditing)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(4)
                
                Button(action: onSaveEditing) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onCancelEditing) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(alignment: .leading) {
                    Text(conversation.title)
                        .lineLimit(1)
                    
                    Text(formatDate(conversation.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    HStack(spacing: 8) {
                        Button(action: onStartEditing) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onExport) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .opacity(0.7)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onSelect()
            }
        }
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ExportOptionsView: View {
    @ObservedObject var viewModel: ConversationListViewModel
    let conversation: Conversation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Export Conversation")
                .font(.headline)
            
            Text("Choose a format:")
                .font(.subheadline)
            
            Button("Plain Text (.txt)") {
                exportConversation(format: .plainText)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("Markdown (.md)") {
                exportConversation(format: .markdown)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("PDF (.pdf)") {
                exportConversation(format: .pdf)
            }
            .buttonStyle(BorderedButtonStyle())
            .frame(width: 200)
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top)
        }
        .padding()
        .frame(width: 250, height: 200)
    }
    
    private func exportConversation(format: ExportFormat) {
        viewModel.exportConversation(conversation: conversation, format: format)
        presentationMode.wrappedValue.dismiss()
    }
}
```

### 2. Accessibility Implementation
1. Add accessibility modifiers to UI components:

```swift
// Example of accessibility improvements for MessageBubble
struct MessageBubble: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(bubbleColor)
                    .foregroundColor(textColor)
                    .cornerRadius(10)
                    .accessibilityLabel(message.role == "user" ? "You said" : "Assistant said")
                    .accessibilityValue(message.content)
                
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Sent at \(formattedTime)")
            }
            
            if message.role != "user" {
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(message.role == "user" ? "Your message" : "Assistant's response")
    }
    
    // Rest of the implementation...
}

// Example of accessibility improvements for DocumentDropArea
struct DocumentDropArea<Content: View>: View {
    // Existing implementation...
    
    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
            )
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool
                // Existing implementation...
            }
            .accessibilityLabel("Document drop area")
            .accessibilityHint("Drag and drop PDF or TXT files here")
    }
}
```

2. Add keyboard shortcuts for common actions:

```swift
// Add to ChatView
struct ChatView: View {
    // Existing implementation...
    
    var body: some View {
        NavigationView {
            // Existing implementation...
        }
        .sheet(isPresented: $isFilePickerPresented) {
            // Existing implementation...
        }
        // Add keyboard shortcuts
        .keyboardShortcut("n", modifiers: [.command], action: createNewConversation)
        .keyboardShortcut("f", modifiers: [.command], action: { showConversationList = true })
        .keyboardShortcut("d", modifiers: [.command], action: { isFilePickerPresented = true })
        // Rest of the implementation...
    }
    
    // Existing methods...
}
```

### 3. Performance Optimization
1. Implement pagination for conversation history:

```swift
class ConversationListViewModel: ObservableObject {
    // Existing properties...
    
    @Published var hasMoreConversations: Bool = false
    private let pageSize: Int = 20
    private var currentPage: Int = 0
    
    // Existing methods...
    
    func loadConversations() {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let conversations = self.databaseManager.getAllConversations(limit: self.pageSize, offset: 0)
            let totalCount = self.databaseManager.getConversationCount()
            
            DispatchQueue.main.async {
                self.conversations = conversations
                self.hasMoreConversations = totalCount > self.pageSize
                self.isLoading = false
            }
        }
    }
    
    func loadMoreConversations() {
        guard hasMoreConversations && !isLoading else {
            return
        }
        
        isLoading = true
        currentPage += 1
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let offset = self.currentPage * self.pageSize
            let newConversations = self.databaseManager.getAllConversations(limit: self.pageSize, offset: offset)
            let totalCount = self.databaseManager.getConversationCount()
            
            DispatchQueue.main.async {
                self.conversations.append(contentsOf: newConversations)
                self.hasMoreConversations = totalCount > (self.currentPage + 1) * self.pageSize
                self.isLoading = false
            }
        }
    }
}
```

2. Optimize message rendering with lazy loading:

```swift
// In ChatView
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(viewModel.messages) { message in
            MessageBubble(message: message)
                .id(message.id)
        }
    }
    .padding()
}
```

3. Implement background processing for document handling:

```swift
func handleDocumentDropped(url: URL) {
    // Show loading indicator
    DispatchQueue.main.async {
        self.isLoading = true
    }
    
    // Process document in background
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        
        do {
            let text = try self.documentHandler.extractText(from: url)
            let tokenCount = self.documentHandler.estimateTokenCount(for: text)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.extractedDocumentText = text
                self.extractedDocumentName = url.lastPathComponent
                self.showExtractedTextEditor = true
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.handleDocumentError(error)
            }
        }
    }
}
```

### 4. UI Tests
1. Create UI tests for the main chat functionality:

```swift
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
```

2. Create UI tests for document handling:

```swift
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
    }
    
    func testExtractedTextEditor() {
        // This test would require setting up a mock document handler
        // to simulate a file drop without actually dropping a file
        
        // For now, we can verify the UI elements exist
        app.statusItems.firstMatch.click()
        
        // Programmatically trigger extracted text editor
        // (This would be done through app internal
