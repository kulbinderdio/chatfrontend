import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchQuery: String = ""
    @Published var currentConversationId: String? = nil
    @Published var hasMoreConversations: Bool = false
    
    private let databaseManager: DatabaseManager
    private let profileManager: ProfileManager
    private let exporter: ConversationExporter
    
    private var cancellables = Set<AnyCancellable>()
    private let pageSize: Int = 20
    private var currentPage: Int = 0
    
    var filteredConversations: [Conversation] {
        if searchQuery.isEmpty {
            return conversations
        } else {
            // Filter conversations by search query
            return conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    var currentConversationTitle: String? {
        conversations.first(where: { $0.id == currentConversationId })?.title
    }
    
    init(databaseManager: DatabaseManager, profileManager: ProfileManager) {
        self.databaseManager = databaseManager
        self.profileManager = profileManager
        self.exporter = ConversationExporter(databaseManager: databaseManager)
        
        loadConversations()
        
        // Set up search publisher
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchConversations(query: query)
            }
            .store(in: &cancellables)
        
        // Listen for conversation history cleared notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConversationHistoryCleared),
            name: Notification.Name("ConversationHistoryCleared"),
            object: nil
        )
    }
    
    @objc private func handleConversationHistoryCleared() {
        // Reload conversations when history is cleared
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clear the conversations list
            self.conversations = []
            self.currentConversationId = nil
            
            // Create a new conversation immediately
            let newConversationId = self.createNewConversation()
            
            // Notify that a new conversation has been created
            NotificationCenter.default.post(
                name: Notification.Name("NewConversationCreated"),
                object: nil,
                userInfo: ["conversationId": newConversationId as Any]
            )
        }
    }
    
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
                
                // Select the first conversation if none is selected
                if self.currentConversationId == nil && !conversations.isEmpty {
                    self.currentConversationId = conversations[0].id
                }
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
    
    func createNewConversation() -> String? {
        // Get selected profile
        let profileId = profileManager.selectedProfileId
        
        // Create a new conversation
        let conversation = databaseManager.createConversation(title: "New Conversation", profileId: profileId)
        
        // Add to list and select it
        DispatchQueue.main.async {
            self.conversations.insert(conversation, at: 0)
            self.currentConversationId = conversation.id
        }
        
        return conversation.id
    }
    
    func selectConversation(id: String) {
        currentConversationId = id
    }
    
    func deleteConversation(id: String) {
        do {
            try databaseManager.deleteConversation(id: id)
            
            // Remove from list
            DispatchQueue.main.async {
                self.conversations.removeAll { $0.id == id }
                
                // If the deleted conversation was selected, select another one
                if self.currentConversationId == id {
                    self.currentConversationId = self.conversations.first?.id
                }
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
    
    func exportConversation(conversation: Conversation, format: ExportFormat) {
        isLoading = true
        
        // Ensure UI operations happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create a save panel
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            
            // Set file name and extension based on format
            switch format {
            case .plainText:
                savePanel.allowedContentTypes = [UTType.plainText]
                savePanel.nameFieldStringValue = "\(conversation.title).txt"
            case .markdown:
                if #available(macOS 11.0, *) {
                    // Create a custom UTType for markdown
                    if let markdownType = UTType("public.markdown-text") ?? UTType("net.daringfireball.markdown") {
                        savePanel.allowedContentTypes = [markdownType]
                    } else {
                        // Fallback to plain text if markdown type is not available
                        savePanel.allowedContentTypes = [UTType.plainText]
                    }
                } else {
                    // Fallback for older macOS versions
                    #if compiler(>=5.3)
                    savePanel.allowedContentTypes = [UTType.plainText]
                    #else
                    savePanel.allowedFileTypes = ["md"]
                    #endif
                }
                savePanel.nameFieldStringValue = "\(conversation.title).md"
            case .pdf:
                savePanel.allowedContentTypes = [UTType.pdf]
                savePanel.nameFieldStringValue = "\(conversation.title).pdf"
            case .json:
                savePanel.allowedContentTypes = [UTType.json]
                savePanel.nameFieldStringValue = "\(conversation.title).json"
            }
            
            // Show save panel
            savePanel.begin { [weak self] result in
                guard let self = self else { return }
                
                if result == .OK, let url = savePanel.url {
                    // Export on a background thread
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try self.exporter.exportConversation(conversation, to: url, format: format)
                            
                            // Open the file on the main thread
                            DispatchQueue.main.async {
                                NSWorkspace.shared.open(url)
                                self.isLoading = false
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.errorMessage = "Failed to export conversation: \(error.localizedDescription)"
                                self.isLoading = false
                            }
                        }
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
    }
}
