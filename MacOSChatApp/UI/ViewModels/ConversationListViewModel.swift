import Foundation
import Combine

class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    
    private let databaseManager: DatabaseManager
    private let profileManager: ProfileManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(databaseManager: DatabaseManager, profileManager: ProfileManager) {
        self.databaseManager = databaseManager
        self.profileManager = profileManager
        
        loadConversations()
        
        // Set up search publisher
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchConversations(query: query)
            }
            .store(in: &cancellables)
    }
    
    func loadConversations() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let conversations = self.databaseManager.getAllConversations()
            
            DispatchQueue.main.async {
                self.conversations = conversations
                self.isLoading = false
            }
        }
    }
    
    func createNewConversation() {
        // Get selected profile
        let profileId = profileManager.selectedProfileId
        
        // Create a new conversation
        let conversation = databaseManager.createConversation(title: "New Conversation", profileId: profileId)
        
        // Add to list
        DispatchQueue.main.async {
            self.conversations.insert(conversation, at: 0)
        }
    }
    
    func deleteConversation(id: String) {
        do {
            try databaseManager.deleteConversation(id: id)
            
            // Remove from list
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
            
            // Update in list
            if let index = conversations.firstIndex(where: { $0.id == id }) {
                DispatchQueue.main.async {
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
            
            // Update in list
            if let index = conversations.firstIndex(where: { $0.id == id }) {
                DispatchQueue.main.async {
                    self.conversations[index].profileId = profileId
                }
            }
        } catch {
            errorMessage = "Failed to update conversation profile: \(error.localizedDescription)"
        }
    }
    
    func searchConversations(query: String) {
        guard !query.isEmpty else {
            loadConversations()
            return
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.databaseManager.searchConversations(query: query)
            
            DispatchQueue.main.async {
                self.conversations = results
                self.isLoading = false
            }
        }
    }
    
    func exportConversation(id: String, to url: URL) {
        guard let conversation = databaseManager.getConversation(id: id) else {
            errorMessage = "Conversation not found"
            return
        }
        
        let exporter = ConversationExporter(databaseManager: databaseManager)
        
        do {
            try exporter.exportConversation(conversation, to: url)
        } catch {
            errorMessage = "Failed to export conversation: \(error.localizedDescription)"
        }
    }
}
