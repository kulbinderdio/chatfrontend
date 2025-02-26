import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Document handling properties
    @Published var extractedDocumentText: String? = nil
    @Published var extractedDocumentName: String? = nil
    @Published var showExtractedTextEditor: Bool = false
    
    private let modelConfigManager: ModelConfigurationManager
    private let databaseManager: DatabaseManager
    let documentHandler: DocumentHandler
    var profileManager: ProfileManager
    
    private(set) var currentConversationId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, databaseManager: DatabaseManager, documentHandler: DocumentHandler, profileManager: ProfileManager) {
        self.modelConfigManager = modelConfigManager
        self.databaseManager = databaseManager
        self.documentHandler = documentHandler
        self.profileManager = profileManager
        
        // Observe profile changes
        profileManager.$selectedProfileId
            .sink { [weak self] _ in
                self?.updateAPIClientForSelectedProfile()
            }
            .store(in: &cancellables)
        
        loadOrCreateConversation()
        updateAPIClientForSelectedProfile()
    }
    
    func updateAPIClientForSelectedProfile() {
        guard let profile = profileManager.getSelectedProfile() else {
            print("DEBUG - ChatViewModel: No selected profile found")
            return
        }
        
        print("DEBUG - ChatViewModel: Selected profile: \(profile.name), Model: \(profile.modelName), Endpoint: \(profile.apiEndpoint)")
        
        // Get API key from Keychain (only if not an Ollama model)
        let apiKey: String
        if profile.modelName.hasPrefix("ollama:") {
            apiKey = "" // Ollama doesn't need an API key
            print("DEBUG - ChatViewModel: Using Ollama model, no API key needed")
        } else {
            apiKey = profileManager.getAPIKey(for: profile.id) ?? ""
            print("DEBUG - ChatViewModel: API key retrieved: \(apiKey.isEmpty ? "Empty" : "Not empty")")
        }
        
        // Update API client configuration
        modelConfigManager.updateConfiguration(
            endpoint: URL(string: profile.apiEndpoint)!,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters
        )
        print("DEBUG - ChatViewModel: API client configuration updated")
        
        // If we have a current conversation, update its profile
        if let conversationId = currentConversationId {
            do {
                try databaseManager.updateConversationProfile(id: conversationId, profileId: profile.id)
                print("DEBUG - ChatViewModel: Conversation profile updated")
            } catch {
                errorMessage = "Failed to update conversation profile: \(error.localizedDescription)"
                print("DEBUG - ChatViewModel: Failed to update conversation profile: \(error.localizedDescription)")
            }
        }
        
        // Force a UI refresh to ensure the profile change is reflected
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func loadOrCreateConversation(id: String? = nil) {
        if let id = id {
            // Load existing conversation
            if let conversation = databaseManager.getConversation(id: id) {
                currentConversationId = conversation.id
                messages = conversation.messages
                
                // If conversation has a profile, use it
                if let profileId = conversation.profileId {
                    if profileManager.profiles.contains(where: { $0.id == profileId }) {
                        profileManager.selectProfile(id: profileId)
                    }
                }
            } else {
                // Conversation not found, create a new one
                createNewConversation()
            }
        } else {
            // Create a new conversation
            createNewConversation()
        }
    }
    
    // Method to directly load a conversation object
    func loadConversation(id: String) {
        if let conversation = databaseManager.getConversation(id: id) {
            currentConversationId = conversation.id
            messages = conversation.messages
            
            // If conversation has a profile, use it
            if let profileId = conversation.profileId {
                if profileManager.profiles.contains(where: { $0.id == profileId }) {
                    profileManager.selectProfile(id: profileId)
                }
            }
        }
    }
    
    private func createNewConversation() {
        // Get selected profile
        let profileId = profileManager.selectedProfileId
        
        // Create a new conversation
        let conversation = databaseManager.createConversation(title: "New Conversation", profileId: profileId)
        currentConversationId = conversation.id
        messages = []
    }
    
    func sendMessage(_ content: String) {
        guard !content.isEmpty else { return }
        
        print("DEBUG - ChatViewModel: Sending message: \(content)")
        
        // Create user message
        let userMessage = Message(role: "user", content: content)
        
        // Add to UI
        messages.append(userMessage)
        print("DEBUG - ChatViewModel: User message added to UI, messages count: \(messages.count)")
        
        // Save to database
        if let conversationId = currentConversationId {
            databaseManager.addMessage(userMessage, toConversation: conversationId)
            print("DEBUG - ChatViewModel: User message saved to database")
        }
        
        // Start loading
        isLoading = true
        
        // Log the current messages being sent
        print("DEBUG - ChatViewModel: Sending \(messages.count) messages to API")
        for (index, msg) in messages.enumerated() {
            print("DEBUG - ChatViewModel: Message \(index): role=\(msg.role), content=\(msg.content.prefix(30))...")
        }
        
        // Make sure we're using the current profile
        updateAPIClientForSelectedProfile()
        
        // Log which profile and model we're using
        if let profile = profileManager.getSelectedProfile() {
            print("DEBUG - ChatViewModel: Using profile for message: \(profile.name)")
            print("DEBUG - ChatViewModel: Using model: \(profile.modelName)")
        }
        
        // Send to API
        modelConfigManager.sendMessage(messages: messages)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else {
                        print("DEBUG - ChatViewModel: Self is nil in receiveCompletion")
                        return
                    }
                    
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.errorMessage = error.localizedDescription
                        print("DEBUG - ChatViewModel: API request failed: \(error.localizedDescription)")
                    } else {
                        print("DEBUG - ChatViewModel: API request completed successfully")
                    }
                },
                receiveValue: { [weak self] message in
                    guard let self = self else {
                        print("DEBUG - ChatViewModel: Self is nil in receiveValue")
                        return
                    }
                    
                    print("DEBUG - ChatViewModel: Received response: \(message.content.prefix(30))...")
                    print("DEBUG - ChatViewModel: Response message ID: \(message.id)")
                    print("DEBUG - ChatViewModel: Response message role: \(message.role)")
                    
                    // Force UI update on main thread
                    DispatchQueue.main.async {
                        // Add to UI
                        self.messages.append(message)
                        print("DEBUG - ChatViewModel: Assistant message added to UI, messages count: \(self.messages.count)")
                        
                        // Save to database
                        if let conversationId = self.currentConversationId {
                            self.databaseManager.addMessage(message, toConversation: conversationId)
                            print("DEBUG - ChatViewModel: Assistant message saved to database")
                        }
                        
                        // Force UI refresh
                        self.objectWillChange.send()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearConversation() {
        // Create a new conversation
        createNewConversation()
    }
    
    // MARK: - Document Handling
    
    func handleDocumentDropped(url: URL) {
        do {
            let text = try documentHandler.extractText(from: url)
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
        sendMessage(text)
        
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
