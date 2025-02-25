import Foundation
@testable import MacOSChatApp

class MockDatabaseManager: DatabaseManager {
    var conversations: [Conversation] = []
    var getConversationResult: Conversation?
    var createConversationResult: Conversation?
    var lastCreatedConversationProfileId: String?
    var lastUpdatedConversationProfileId: String?
    var messages: [String: [Message]] = [:] // Conversation ID -> Messages
    
    override func getAllConversations(limit: Int = 100, offset: Int = 0) -> [Conversation] {
        if offset >= conversations.count {
            return []
        }
        
        let endIndex = min(offset + limit, conversations.count)
        return Array(conversations[offset..<endIndex])
    }
    
    override func getConversationCount() -> Int {
        return conversations.count
    }
    
    override func getConversation(id: String) -> Conversation? {
        if let result = getConversationResult {
            return result
        }
        return conversations.first { $0.id == id }
    }
    
    override func createConversation(title: String, profileId: String? = nil) -> Conversation {
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
            messages[conversation.id] = []
            return conversation
        }
    }
    
    override func deleteConversation(id: String) throws {
        conversations.removeAll { $0.id == id }
        messages.removeValue(forKey: id)
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
    
    override func addMessage(_ message: Message, toConversation conversationId: String) {
        if messages[conversationId] == nil {
            messages[conversationId] = []
        }
        
        messages[conversationId]?.append(message)
        
        // Update the conversation's messages
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].messages = messages[conversationId] ?? []
        }
    }
    
    override func getMessages(forConversation conversationId: String) -> [Message] {
        return messages[conversationId] ?? []
    }
}
