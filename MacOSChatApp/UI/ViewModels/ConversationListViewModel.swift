import Foundation
import Combine

class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    
    private let databaseManager: DatabaseManager
    private let exporter: ConversationExporter
    
    private var cancellables = Set<AnyCancellable>()
    
    init(databaseManager: DatabaseManager, exporter: ConversationExporter) {
        self.databaseManager = databaseManager
        self.exporter = exporter
        
        // Set up search query publisher
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
        
        // Load initial conversations
        loadConversations()
    }
    
    func loadConversations() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let conversations = self.databaseManager.getAllConversations()
            
            DispatchQueue.main.async {
                self.conversations = conversations
                self.isLoading = false
            }
        }
    }
    
    func createNewConversation(title: String = "New Conversation", profileId: String? = nil) -> String? {
        let conversation = databaseManager.createConversation(title: title, profileId: profileId)
        
        // Add to the list
        DispatchQueue.main.async {
            self.conversations.insert(conversation, at: 0)
        }
        
        return conversation.id
    }
    
    func deleteConversation(id: String) {
        do {
            try databaseManager.deleteConversation(id: id)
            
            // Remove from the list
            DispatchQueue.main.async {
                self.conversations.removeAll { $0.id == id }
            }
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }
    
    func updateConversationTitle(id: String, title: String) {
        do {
            try databaseManager.updateConversationTitle(id: id, title: title)
            
            // Update in the list
            DispatchQueue.main.async {
                if let index = self.conversations.firstIndex(where: { $0.id == id }) {
                    self.conversations[index].title = title
                }
            }
        } catch {
            errorMessage = "Failed to update conversation title: \(error.localizedDescription)"
        }
    }
    
    func updateConversationProfile(id: String, profileId: String?) {
        do {
            try databaseManager.updateConversationProfile(id: id, profileId: profileId)
            
            // Update in the list
            DispatchQueue.main.async {
                if let index = self.conversations.firstIndex(where: { $0.id == id }) {
                    self.conversations[index].profileId = profileId
                }
            }
        } catch {
            errorMessage = "Failed to update conversation profile: \(error.localizedDescription)"
        }
    }
    
    func exportConversation(id: String, format: ExportFormat) -> URL? {
        return exporter.exportConversation(id: id, format: format)
    }
    
    private func performSearch(query: String) {
        if query.isEmpty {
            loadConversations()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.databaseManager.searchConversations(query: query)
            
            DispatchQueue.main.async {
                self.conversations = results
                self.isLoading = false
            }
        }
    }
}
