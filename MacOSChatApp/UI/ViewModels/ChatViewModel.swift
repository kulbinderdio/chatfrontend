import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var streamedResponse: String = ""
    
    private var modelConfigManager: ModelConfigurationManager
    private var databaseManager: DatabaseManager
    private var documentHandler: DocumentHandler
    
    private var currentConversationId: String?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelConfigManager: ModelConfigurationManager, databaseManager: DatabaseManager, documentHandler: DocumentHandler) {
        self.modelConfigManager = modelConfigManager
        self.databaseManager = databaseManager
        self.documentHandler = documentHandler
        
        loadOrCreateConversation()
    }
    
    // MARK: - Conversation Management
    
    private func loadOrCreateConversation() {
        // For preview in SwiftUI Canvas
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            messages = [
                Message(id: "1", role: "user", content: "Hello, how are you?", timestamp: Date().addingTimeInterval(-60)),
                Message(id: "2", role: "assistant", content: "I'm doing well, thank you for asking! How can I help you today?", timestamp: Date())
            ]
            return
        }
        #endif
        
        // Load the most recent conversation or create a new one
        if let conversationId = UserDefaults.standard.string(forKey: "currentConversationId"),
           let _ = databaseManager.getConversation(id: conversationId) {
            currentConversationId = conversationId
            messages = databaseManager.getMessages(forConversation: conversationId)
        } else {
            createNewConversation()
        }
    }
    
    func createNewConversation() {
        let conversation = databaseManager.createConversation(title: "New Conversation")
        currentConversationId = conversation.id
        UserDefaults.standard.set(conversation.id, forKey: "currentConversationId")
        messages = []
    }
    
    // MARK: - Message Handling
    
    func sendMessage(content: String) {
        guard let conversationId = currentConversationId else {
            errorMessage = "No active conversation"
            return
        }
        
        // Create user message
        let userMessageId = UUID().uuidString
        let userMessage = Message(id: userMessageId, role: "user", content: content, timestamp: Date())
        
        // Add to messages and save to database
        messages.append(userMessage)
        databaseManager.addMessage(userMessage, toConversation: conversationId)
        
        // Reset streamed response
        streamedResponse = ""
        
        // Send to API
        isLoading = true
        errorMessage = nil
        
        // Stream the response
        modelConfigManager.streamMessage(messages: messages)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self.handleAPIError(error)
                    } else if !self.streamedResponse.isEmpty {
                        // Save the complete response when streaming is done
                        self.saveAssistantResponse(self.streamedResponse)
                    }
                },
                receiveValue: { [weak self] chunk in
                    guard let self = self else { return }
                    self.streamedResponse += chunk
                }
            )
            .store(in: &cancellables)
    }
    
    private func saveAssistantResponse(_ content: String) {
        guard let conversationId = currentConversationId else {
            return
        }
        
        // Create assistant message
        let assistantMessageId = UUID().uuidString
        let assistantMessage = Message(
            id: assistantMessageId,
            role: "assistant",
            content: content,
            timestamp: Date()
        )
        
        // Add to messages and save to database
        messages.append(assistantMessage)
        databaseManager.addMessage(assistantMessage, toConversation: conversationId)
        
        // Update conversation title if this is the first exchange
        if messages.count == 2 {
            let title = generateConversationTitle(from: messages[0].content)
            var conversation = databaseManager.getConversation(id: conversationId)!
            conversation.title = title
            databaseManager.updateConversation(conversation)
        }
    }
    
    // MARK: - Document Handling
    
    func handleDocumentDropped(url: URL) {
        do {
            isLoading = true
            errorMessage = nil
            
            // Extract text from document
            let extractedText = try documentHandler.extractText(from: url)
            
            // Create system message with extracted text
            let systemMessageId = UUID().uuidString
            let systemMessage = Message(
                id: systemMessageId,
                role: "system",
                content: "Content from \(url.lastPathComponent):\n\n\(extractedText)",
                timestamp: Date()
            )
            
            // Add to messages
            messages.append(systemMessage)
            
            // Save to database if in a conversation
            if let conversationId = currentConversationId {
                databaseManager.addMessage(systemMessage, toConversation: conversationId)
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to extract text from document: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAPIError(_ error: APIClientError) {
        switch error {
        case .authenticationFailed:
            errorMessage = "Authentication failed. Please check your API key in settings."
        case .rateLimited:
            errorMessage = "Rate limit exceeded. Please try again later."
        case .serverError(let code):
            errorMessage = "Server error (\(code)). Please try again later."
        case .requestFailed(let underlyingError):
            errorMessage = "Request failed: \(underlyingError.localizedDescription)"
        case .invalidURL:
            errorMessage = "Invalid API URL. Please check your settings."
        case .invalidResponse:
            errorMessage = "Invalid response from server. Please try again."
        case .unknownError:
            errorMessage = "An unknown error occurred. Please try again."
        }
    }
    
    // MARK: - Helpers
    
    private func generateConversationTitle(from firstMessage: String) -> String {
        // Simple implementation - use first few words of first message
        let words = firstMessage.split(separator: " ")
        let titleWords = words.prefix(4)
        let title = titleWords.joined(separator: " ")
        return title.count > 0 ? title + "..." : "New Conversation"
    }
}
