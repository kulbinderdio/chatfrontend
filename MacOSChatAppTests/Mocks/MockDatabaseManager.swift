import Foundation
@testable import MacOSChatApp

class MockDatabaseManager: DatabaseManager {
    var conversations: [Conversation] = []
    var getConversationResult: Conversation?
    var createConversationResult: Conversation?
    var lastCreatedConversationProfileId: String?
    var lastUpdatedConversationProfileId: String?
    
    func getAllConversations(limit: Int = 100) -> [Conversation] {
        return conversations
    }
    
    override func getConversation(id: String) -> Conversation? {
        return getConversationResult
    }
    
    override func createConversation(title: String, profileId: String?) -> Conversation {
        lastCreatedConversationProfileId = profileId
        
        if let result = createConversationResult {
            conversations.append(result)
            return result
        } else {
            let conversation = Conversation(
                id: UUID().uuidString,
                title: title,
                messages: [],
                createdAt: Date(),
                updatedAt: Date(),
                profileId: profileId
            )
            
            conversations.append(conversation)
            return conversation
        }
    }
    
    override func deleteConversation(id: String) throws {
        conversations.removeAll { $0.id == id }
    }
    
    override func updateConversationTitle(id: String, title: String) throws {
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations[index].title = title
        }
    }
    
    override func searchConversations(query: String) -> [Conversation] {
        return conversations.filter { $0.title.lowercased().contains(query.lowercased()) }
    }
    
    override func updateConversationProfile(id: String, profileId: String?) throws {
        lastUpdatedConversationProfileId = profileId
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations[index].profileId = profileId
        }
    }
}
