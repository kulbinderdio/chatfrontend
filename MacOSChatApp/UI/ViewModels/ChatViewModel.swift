import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let modelConfigManager: ModelConfigurationManager
    private let databaseManager: DatabaseManager
    private let documentHandler: DocumentHandler
    private let profileManager: ProfileManager
    
    private var currentConversationId: String?
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
    
    func handleDocumentDropped(url: URL) {
        processDocuments([url])
    }
    
    func processDocuments(_ urls: [URL]) {
        isLoading = true
        
        documentHandler.processDocuments(urls) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let content):
                    self?.sendMessage(content)
                case .failure(let error):
                    self?.errorMessage = "Failed to process document: \(error.localizedDescription)"
                }
            }
        }
    }
}
