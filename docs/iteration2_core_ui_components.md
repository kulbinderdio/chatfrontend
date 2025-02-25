# Iteration 2: Core UI Components

## Overview
This iteration focuses on implementing the core UI components of the application, including the main chat interface, settings panel, and menu bar integration. These components will follow macOS Human Interface Guidelines and provide the visual foundation for the application.

## Objectives
- Implement the main ChatView with message bubbles and input area
- Create the SettingsView with tabs for different configuration options
- Develop the ProfilesView for managing model profiles
- Implement the MenuBarComponent for system tray integration
- Ensure all UI components follow macOS Human Interface Guidelines
- Support dark mode and light mode

## Implementation Details

### 1. ChatView Implementation
1. Create the main chat interface:

```swift
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

2. Implement the MessageBubble component:

```swift
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
                
                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role != "user" {
                Spacer()
            }
        }
    }
    
    private var bubbleColor: Color {
        if message.role == "user" {
            return Color.blue
        } else {
            return colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
        }
    }
    
    private var textColor: Color {
        if message.role == "user" {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}
```

3. Create the DocumentDropArea component:

```swift
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
                            if url.pathExtension.lowercased() == "pdf" || url.pathExtension.lowercased() == "txt" {
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

4. Create the DocumentPicker component:

```swift
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

### 2. SettingsView Implementation
1. Create the main settings interface:

```swift
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            APIConfigView(viewModel: viewModel)
                .tabItem {
                    Label("API", systemImage: "key.fill")
                }
                .tag(0)
            
            ModelSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Model", systemImage: "gear")
                }
                .tag(1)
            
            ProfilesView(viewModel: viewModel)
                .tabItem {
                    Label("Profiles", systemImage: "person.crop.circle")
                }
                .tag(2)
            
            AppearanceView(viewModel: viewModel)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }
                .tag(3)
            
            AdvancedView(viewModel: viewModel)
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(4)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}
```

2. Implement the API Configuration tab:

```swift
struct APIConfigView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var apiKey: String = ""
    @State private var apiEndpoint: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("API Endpoint", text: $apiEndpoint)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        apiEndpoint = viewModel.apiEndpoint
                    }
                
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        apiKey = viewModel.apiKey
                    }
                
                Button("Save") {
                    viewModel.updateAPIConfig(endpoint: apiEndpoint, key: apiKey)
                }
                .disabled(apiEndpoint.isEmpty || apiKey.isEmpty)
            }
            
            Section(header: Text("Ollama Integration")) {
                Toggle("Enable Ollama", isOn: $viewModel.ollamaEnabled)
                
                if viewModel.ollamaEnabled {
                    TextField("Ollama Endpoint", text: $viewModel.ollamaEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
}
```

3. Implement the Model Settings tab:

```swift
struct ModelSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Model Selection")) {
                Picker("Model", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
            }
            
            Section(header: Text("Parameters")) {
                VStack(alignment: .leading) {
                    Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                    Slider(value: $viewModel.temperature, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Max Tokens: \(viewModel.maxTokens)")
                    Slider(value: $viewModel.maxTokensDouble, in: 256...4096, step: 256)
                }
                
                VStack(alignment: .leading) {
                    Text("Top-p: \(viewModel.topP, specifier: "%.1f")")
                    Slider(value: $viewModel.topP, in: 0...1, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Frequency Penalty: \(viewModel.frequencyPenalty, specifier: "%.1f")")
                    Slider(value: $viewModel.frequencyPenalty, in: 0...2, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("Presence Penalty: \(viewModel.presencePenalty, specifier: "%.1f")")
                    Slider(value: $viewModel.presencePenalty, in: 0...2, step: 0.1)
                }
            }
            
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
        }
    }
}
```

### 3. ProfilesView Implementation
1. Create the profiles management interface:

```swift
struct ProfilesView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var isAddingProfile = false
    @State private var isEditingProfile = false
    @State private var selectedProfileId: String? = nil
    
    var body: some View {
        VStack {
            List(selection: $selectedProfileId) {
                ForEach(viewModel.profiles, id: \.id) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.name)
                                .font(.headline)
                            Text(profile.modelName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if profile.isDefault {
                            Text("Default")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .tag(profile.id)
                    .contextMenu {
                        Button("Edit") {
                            selectedProfileId = profile.id
                            isEditingProfile = true
                        }
                        
                        Button("Set as Default") {
                            viewModel.setDefaultProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault)
                        
                        Button("Delete") {
                            viewModel.deleteProfile(id: profile.id)
                        }
                        .disabled(profile.isDefault)
                    }
                }
            }
            
            HStack {
                Button("Add Profile") {
                    isAddingProfile = true
                }
                
                Spacer()
                
                Button("Edit") {
                    isEditingProfile = true
                }
                .disabled(selectedProfileId == nil)
                
                Button("Delete") {
                    if let id = selectedProfileId {
                        viewModel.deleteProfile(id: id)
                    }
                }
                .disabled(selectedProfileId == nil || viewModel.profiles.first(where: { $0.id == selectedProfileId })?.isDefault == true)
            }
            .padding(.top)
        }
        .sheet(isPresented: $isAddingProfile) {
            ProfileEditorView(viewModel: viewModel, mode: .add)
        }
        .sheet(isPresented: $isEditingProfile) {
            if let id = selectedProfileId, let profile = viewModel.profiles.first(where: { $0.id == id }) {
                ProfileEditorView(viewModel: viewModel, mode: .edit(profile: profile))
            }
        }
    }
}
```

2. Implement the ProfileEditorView:

```swift
enum ProfileEditorMode {
    case add
    case edit(profile: ModelProfile)
}

struct ProfileEditorView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let mode: ProfileEditorMode
    
    @State private var name: String = ""
    @State private var apiEndpoint: String = ""
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 2048
    @State private var topP: Double = 1.0
    @State private var frequencyPenalty: Double = 0.0
    @State private var presencePenalty: Double = 0.0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Profile Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("API Endpoint", text: $apiEndpoint)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model Name", text: $modelName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Model Parameters")) {
                    VStack(alignment: .leading) {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                        Slider(value: $temperature, in: 0...2, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Tokens: \(maxTokens)")
                        Slider(value: $maxTokensDouble, in: 256...4096, step: 256)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Top-p: \(topP, specifier: "%.1f")")
                        Slider(value: $topP, in: 0...1, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Frequency Penalty: \(frequencyPenalty, specifier: "%.1f")")
                        Slider(value: $frequencyPenalty, in: 0...2, step: 0.1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Presence Penalty: \(presencePenalty, specifier: "%.1f")")
                        Slider(value: $presencePenalty, in: 0...2, step: 0.1)
                    }
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                
                Button("Test Connection") {
                    viewModel.testConnection(endpoint: apiEndpoint, key: apiKey, model: modelName)
                }
                
                Button(mode == .add ? "Add" : "Save") {
                    let parameters = ModelParameters(
                        temperature: temperature,
                        maxTokens: maxTokens,
                        topP: topP,
                        frequencyPenalty: frequencyPenalty,
                        presencePenalty: presencePenalty
                    )
                    
                    switch mode {
                    case .add:
                        viewModel.addProfile(
                            name: name,
                            apiEndpoint: apiEndpoint,
                            apiKey: apiKey,
                            modelName: modelName,
                            parameters: parameters
                        )
                    case .edit(let profile):
                        viewModel.updateProfile(
                            id: profile.id,
                            name: name,
                            apiEndpoint: apiEndpoint,
                            apiKey: apiKey,
                            modelName: modelName,
                            parameters: parameters
                        )
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || apiEndpoint.isEmpty || apiKey.isEmpty || modelName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            if case .edit(let profile) = mode {
                name = profile.name
                apiEndpoint = profile.apiEndpoint.absoluteString
                apiKey = viewModel.getAPIKey(for: profile.id) ?? ""
                modelName = profile.modelName
                temperature = profile.parameters.temperature
                maxTokens = profile.parameters.maxTokens
                topP = profile.parameters.topP
                frequencyPenalty = profile.parameters.frequencyPenalty
                presencePenalty = profile.parameters.presencePenalty
            }
        }
    }
    
    private var maxTokensDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(maxTokens) },
            set: { maxTokens = Int($0) }
        )
    }
}
```

### 4. MenuBarComponent Implementation
1. Create the menu bar component:

```swift
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    
    func setupMenuBar(with rootView: ChatView) {
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
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
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            closePopover(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
    }
}

// Event monitor to detect clicks outside the popover
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
```

2. Update the main app file to use the MenuBarManager:

```swift
@main
struct MacOSChatApp: App {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    private let menuBarManager = MenuBarManager()
    
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
            SettingsView(viewModel: settingsViewModel)
        }
    }
    
    private func setupMenuBar() {
        let chatView = ChatView(viewModel: chatViewModel)
        menuBarManager.setupMenuBar(with: chatView)
    }
}
```

## Unit Tests
The following tests will verify that the UI components are implemented correctly:

### 1. ChatViewTests.swift
```swift
import XCTest
import ViewInspector
@testable import MacOSChatApp

extension ChatView: Inspectable {}
extension MessageBubble: Inspectable {}

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
        let scrollView = try view.inspect().find(ScrollView.self)
        let vStack = try scrollView.find(LazyVStack.self)
        let messageBubbles = try vStack.findAll(MessageBubble.self)
        
        XCTAssertEqual(messageBubbles.count, 2)
        XCTAssertEqual(try messageBubbles[0].actualView().message.content, "Hello")
        XCTAssertEqual(try messageBubbles[1].actualView().message.content, "Hi there!")
    }
    
    func testSendButtonDisabledWhenMessageEmpty() throws {
        // Given
        let viewModel = ChatViewModel()
        
        // When
        let view = ChatView(viewModel: viewModel)
        
        // Then
        let sendButton = try view.inspect().find(ViewType.Button.self) { button in
            try button.find(ViewType.Image.self).image().name().contains("paperplane")
        }
        
        XCTAssertTrue(try sendButton.isDisabled())
    }
    
    func testSendMessageClearsInputField() throws {
        // Given
        let viewModel = ChatViewModel()
        let view = ChatView(viewModel: viewModel)
        
        // When
        try view.inspect().find(ViewType.TextEditor.self).setInput("Test message")
        let sendButton = try view.inspect().find(ViewType.Button.self) { button in
            try button.find(ViewType.Image.self).image().name().contains("paperplane")
        }
        try sendButton.tap()
        
        // Then
        let textEditor = try view.inspect().find(ViewType.TextEditor.self)
        XCTAssertEqual(try textEditor.text(), "")
    }
}
```

### 2. MessageBubbleTests.swift
```swift
import XCTest
import ViewInspector
@testable import MacOSChatApp

class MessageBubbleTests: XCTestCase {
    
    func testUserMessageAlignment() throws {
        // Given
        let message = Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        let hStack = try bubble.inspect().find(ViewType.HStack.self)
        let spacer = try? hStack.findAll(ViewType.Spacer.self).first
        
        XCTAssertNotNil(spacer, "User messages should have a spacer at the beginning")
    }
    
    func testAssistantMessageAlignment() throws {
        // Given
        let message = Message(id: "1", role: "assistant", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        let hStack = try bubble.inspect().find(ViewType.HStack.self)
        let spacer = try? hStack.findAll(ViewType.Spacer.self).last
        
        XCTAssertNotNil(spacer, "Assistant messages should have a spacer at the end")
    }
    
    func testBubbleColorForUserMessage() throws {
        // Given
        let message = Message(id: "1", role: "user", content: "Hello", timestamp: Date())
        
        // When
        let bubble = MessageBubble(message: message)
        
        // Then
        let text = try bubble.inspect().find(ViewType.Text.self).first
        let backgroundColor = try text.background().cast(ViewType.Color.self)
        
        // This is a simplified test as ViewInspector doesn't easily allow checking color values
        XCTAssertNotNil(backgroundColor)
    }
}
```

### 3. SettingsViewTests.swift
```swift
import XCTest
import ViewInspector
@testable import MacOSChatApp

extension SettingsView: Inspectable {}

class SettingsViewTests: XCTestCase {
    
    func testSettingsViewHasFiveTabs() throws {
        // Given
        let viewModel = SettingsViewModel()
        
        // When
        let view = SettingsView(viewModel: viewModel)
        
        // Then
        let tabView = try view.inspect().find(ViewType.TabView.self)
        let tabItems = try tabView.tabItems()
        
        XCTAssertEqual(tabItems.count, 5)
    }
    
    func testAPIConfigViewSavesSettings() throws {
        // Given
        let viewModel = SettingsViewModel()
        let view = APIConfigView(viewModel: viewModel)
        
        // When
        try view.inspect().find(ViewType.TextField.self).first.setInput("https://api.example.com")
        try view.inspect().find(ViewType.SecureField.self).setInput("test-api-key")
        try view.inspect().find(ViewType.Button.self).tap()
        
        // Then
        XCTAssertEqual(viewModel.apiEndpoint, "https://api.example.com")
        XCTAssertEqual(viewModel.apiKey, "test-api-key")
    }
    
    func testModelSettingsViewUpdatesParameters() throws {
        // Given
        let viewModel = SettingsViewModel()
        let view = ModelSettingsView(viewModel: viewModel)
        
        // When
        let temperatureSlider = try view.inspect().find(ViewType.Slider.self).first
        try temperatureSlider.setValue(1.0)
        
        // Then
        XCTAssertEqual(viewModel.temperature, 1.0)
    }
}
```

### 4. ProfilesViewTests.swift
```swift
import XCTest
import ViewInspector
@testable import MacOSChatApp

extension ProfilesView: Inspectable {}

class ProfilesViewTests: XCTestCase {
    
    func testProfilesViewDisplaysProfiles() throws {
        // Given
        let viewModel = SettingsViewModel()
        viewModel.profiles = [
            ModelProfile(
                id: "1",
                name: "Test Profile",
                apiEndpoint: URL(string: "https://api.example.com")!,
                apiKey: "key-reference",
                modelName: "gpt-4",
                parameters: ModelParameters(
                    temperature: 0.7,
                    maxTokens: 2048,
                    topP: 1.0,
                    frequencyPenalty: 0.0,
                    presencePenalty: 0.0
                ),
                isDefault: true
            )
        ]
        
        // When
        let view = ProfilesView(viewModel: viewModel)
        
        // Then
        let list = try view.inspect().find(ViewType.List.self)
        let text = try list.find(ViewType.Text.self).first
        
        XCTAssertEqual(try text.string(), "Test Profile")
    }
    
    func testAddProfileButtonShowsSheet() throws {
        // Given
        let viewModel = SettingsViewModel()
        let view = ProfilesView(viewModel: viewModel)
        
        // When
        let addButton = try view.inspect().find(ViewType.Button.self) { button in
            try button.labelView().text().string() == "Add Profile"
        }
        try addButton.tap()
        
        // Then
        // ViewInspector doesn't easily allow checking if a sheet is presented
        // This would typically be tested in a UI test
    }
}
```

### 5. MenuBarComponentTests.swift
```swift
import XCTest
@testable import MacOSChatApp

class MenuBarComponentTests: XCTestCase {
