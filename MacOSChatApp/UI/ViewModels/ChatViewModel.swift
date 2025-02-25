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
    private let profileManager: ProfileManager
    
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
    
    private func updateAPIClientForSelectedProfile() {
        guard let profile = profileManager.getSelectedProfile() else {
            return
        }
        
        // Get API key from Keychain
        let apiKey = profileManager.getAPIKey(for: profile.id) ?? ""
        
        // Update API client configuration
        modelConfigManager.updateConfiguration(
            endpoint: URL(string: profile.apiEndpoint)!,
            apiKey: apiKey,
            modelName: profile.modelName,
            parameters: profile.parameters
        )
        
        // If we have a current conversation, update its profile
        if let conversationId = currentConversationId {
            do {
                try databaseManager.updateConversationProfile(id: conversationId, profileId: profile.id)
            } catch {
                errorMessage = "Failed to update conversation profile: \(error.localizedDescription)"
            }
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
        
        // Create user message
        let userMessage = Message(role: "user", content: content)
        
        // Add to UI
        messages.append(userMessage)
        
        // Save to database
        if let conversationId = currentConversationId {
            databaseManager.addMessage(userMessage, toConversation: conversationId)
        }
        
        // Start loading
        isLoading = true
        
        // Send to API
        modelConfigManager.sendMessage(messages: messages)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] message in
                    guard let self = self else { return }
                    
                    // Add to UI
                    self.messages.append(message)
                    
                    // Save to database
                    if let conversationId = self.currentConversationId {
                        self.databaseManager.addMessage(message, toConversation: conversationId)
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
