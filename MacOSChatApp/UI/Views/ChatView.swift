import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var conversationListViewModel: ConversationListViewModel
    @State private var messageText: String = ""
    @State private var isFilePickerPresented: Bool = false
    @State private var showConversationList: Bool = false
    
    // Get a reference to the MenuBarManager to access the popover window
    @EnvironmentObject private var menuBarManager: MenuBarManager
    
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
                VStack(spacing: 8) {
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
                    
                    // Profile selector
                    HStack {
                        Text("Profile:")
                            .font(.subheadline)
                        
                        Picker("Profile", selection: $viewModel.profileManager.selectedProfileId) {
                            ForEach(viewModel.profileManager.profiles) { profile in
                                Text(profile.name).tag(profile.id as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 200)
                        .onChange(of: viewModel.profileManager.selectedProfileId) { newProfileId in
                            viewModel.updateAPIClientForSelectedProfile()
                        }
                        
                        Spacer()
                    }
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
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel(message.role == "user" ? "You said" : "Assistant said")
                                    .accessibilityValue(message.content)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                    // Add a second onChange to force refresh when objectWillChange is sent
                    .onReceive(viewModel.objectWillChange) { _ in
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
                            .accessibilityLabel("Message input")
                    }
                    .accessibilityLabel("Document drop area")
                    .accessibilityHint("Drag and drop PDF or TXT files here")
                    
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
                viewModel.loadOrCreateConversation(id: conversationId)
            }
        }
        // Listen for changes in the conversation list
        .onReceive(conversationListViewModel.$conversations) { _ in
            // If there are no conversations, clear the current conversation
            if conversationListViewModel.conversations.isEmpty {
                viewModel.messages = []
                viewModel.createNewConversation()
            }
        }
        .onChange(of: conversationListViewModel.currentConversationId) { newConversationId in
            // Load the selected conversation when it changes
            if let conversationId = newConversationId {
                viewModel.loadOrCreateConversation(id: conversationId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NewChatRequested"))) { _ in
            createNewConversation()
        }
        // Add keyboard shortcuts
        .keyboardShortcut("n", modifiers: [.command]) { createNewConversation() }
        .keyboardShortcut("f", modifiers: [.command]) { showConversationList = true }
        .keyboardShortcut("d", modifiers: [.command]) { isFilePickerPresented = true }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty && !viewModel.isLoading {
            viewModel.sendMessage(trimmedText)
            messageText = ""
        }
    }
    
    private func createNewConversation() {
        if let newConversationId = conversationListViewModel.createNewConversation() {
            viewModel.loadOrCreateConversation(id: newConversationId)
        }
    }
}

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers, action: @escaping () -> Void) -> some View {
        self.overlay(
            Button("") {
                action()
            }
            .keyboardShortcut(key, modifiers: modifiers)
            .opacity(0)
        )
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let keychainManager = KeychainManager()
        let userDefaultsManager = UserDefaultsManager()
        let modelConfigManager = ModelConfigurationManager(keychainManager: keychainManager, userDefaultsManager: userDefaultsManager)
        
        // Create a mock database manager that doesn't throw
        let databaseManager: DatabaseManager
        do {
            databaseManager = try DatabaseManager()
        } catch {
            fatalError("Failed to initialize DatabaseManager for preview: \(error.localizedDescription)")
        }
        
        let documentHandler = DocumentHandler()
        let profileManager = ProfileManager(databaseManager: databaseManager, keychainManager: keychainManager)
        
        let viewModel = ChatViewModel(
            modelConfigManager: modelConfigManager,
            databaseManager: databaseManager,
            documentHandler: documentHandler,
            profileManager: profileManager
        )
        
        let conversationListViewModel = ConversationListViewModel(
            databaseManager: databaseManager,
            profileManager: profileManager
        )
        
        return ChatView(
            viewModel: viewModel,
            conversationListViewModel: conversationListViewModel
        )
    }
}
