import Foundation
import SQLite

class DatabaseManager {
    private let db: Connection
    
    init() throws {
        // Get the application support directory
        let fileManager = FileManager.default
        let appSupportDir = try fileManager.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        
        // Create app-specific directory if it doesn't exist
        let appDir = appSupportDir.appendingPathComponent("MacOSChatApp", isDirectory: true)
        if !fileManager.fileExists(atPath: appDir.path) {
            try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        // Open or create the database
        let dbPath = appDir.appendingPathComponent("chat_history.sqlite").path
        db = try Connection(dbPath)
        
        // Create tables if they don't exist
        try DatabaseSchema.createTables(db: db)
        
        print("DatabaseManager initialized")
    }
    
    // MARK: - Conversation Methods
    
    func createConversation(title: String, profileId: String? = nil) -> Conversation {
        let id = UUID().uuidString
        let now = Date()
        
        let insert = DatabaseSchema.conversations.insert(
            DatabaseSchema.conversationId <- id,
            DatabaseSchema.conversationTitle <- title,
            DatabaseSchema.conversationCreatedAt <- now,
            DatabaseSchema.conversationUpdatedAt <- now,
            DatabaseSchema.conversationProfileId <- profileId
        )
        
        do {
            try db.run(insert)
            print("Created conversation: \(id)")
            
            return Conversation(
                id: id,
                title: title,
                messages: [],
                createdAt: now,
                updatedAt: now,
                profileId: profileId
            )
        } catch {
            print("Failed to create conversation: \(error.localizedDescription)")
            // Return a conversation anyway for now, but in a real app we would handle this error
            return Conversation(
                id: id,
                title: title,
                messages: [],
                createdAt: now,
                updatedAt: now,
                profileId: profileId
            )
        }
    }
    
    func getConversation(id: String) -> Conversation? {
        let query = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        do {
            if let row = try db.pluck(query) {
                print("Fetching conversation: \(id)")
                
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    messages: getMessages(forConversation: id),
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                
                return conversation
            }
        } catch {
            print("Error getting conversation: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func getAllConversations(limit: Int = 50, offset: Int = 0) -> [Conversation] {
        let query = DatabaseSchema.conversations
            .order(DatabaseSchema.conversationUpdatedAt.desc)
            .limit(limit, offset: offset)
        
        var conversations: [Conversation] = []
        
        do {
            print("Fetching all conversations")
            
            for row in try db.prepare(query) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    messages: [], // Don't load messages here for performance
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                conversations.append(conversation)
            }
        } catch {
            print("Error getting all conversations: \(error.localizedDescription)")
        }
        
        return conversations
    }
    
    func updateConversation(_ conversation: Conversation) {
        let query = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == conversation.id)
        
        let update = query.update(
            DatabaseSchema.conversationTitle <- conversation.title,
            DatabaseSchema.conversationUpdatedAt <- conversation.updatedAt,
            DatabaseSchema.conversationProfileId <- conversation.profileId
        )
        
        do {
            try db.run(update)
            print("Updated conversation: \(conversation.id)")
        } catch {
            print("Error updating conversation: \(error.localizedDescription)")
        }
    }
    
    func updateConversationTitle(id: String, title: String) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        let update = conversation.update(
            DatabaseSchema.conversationTitle <- title,
            DatabaseSchema.conversationUpdatedAt <- Date()
        )
        
        do {
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update conversation title: \(error.localizedDescription)")
        }
    }
    
    func updateConversationProfile(id: String, profileId: String?) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        let update = conversation.update(
            DatabaseSchema.conversationProfileId <- profileId,
            DatabaseSchema.conversationUpdatedAt <- Date()
        )
        
        do {
            if try db.run(update) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update conversation profile: \(error.localizedDescription)")
        }
    }
    
    func deleteConversation(id: String) throws {
        let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == id)
        
        do {
            if try db.run(conversation.delete()) > 0 {
                print("Deleted conversation: \(id)")
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete conversation: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Message Methods
    
    func addMessage(_ message: Message, toConversation conversationId: String) {
        let insert = DatabaseSchema.messages.insert(
            DatabaseSchema.messageId <- message.id,
            DatabaseSchema.messageConversationId <- conversationId,
            DatabaseSchema.messageRole <- message.role,
            DatabaseSchema.messageContent <- message.content,
            DatabaseSchema.messageTimestamp <- message.timestamp
        )
        
        do {
            try db.run(insert)
            
            // Update conversation's updatedAt timestamp
            let conversation = DatabaseSchema.conversations.filter(DatabaseSchema.conversationId == conversationId)
            let update = conversation.update(DatabaseSchema.conversationUpdatedAt <- Date())
            try db.run(update)
            
            print("Added message \(message.id) to conversation \(conversationId)")
        } catch {
            print("Error adding message: \(error.localizedDescription)")
        }
    }
    
    func getMessages(forConversation conversationId: String) -> [Message] {
        let query = DatabaseSchema.messages
            .filter(DatabaseSchema.messageConversationId == conversationId)
            .order(DatabaseSchema.messageTimestamp.asc)
        
        var messages: [Message] = []
        
        do {
            print("Fetching messages for conversation: \(conversationId)")
            
            for row in try db.prepare(query) {
                let message = Message(
                    id: row[DatabaseSchema.messageId],
                    role: row[DatabaseSchema.messageRole],
                    content: row[DatabaseSchema.messageContent],
                    timestamp: row[DatabaseSchema.messageTimestamp]
                )
                messages.append(message)
            }
        } catch {
            print("Error getting messages: \(error.localizedDescription)")
        }
        
        return messages
    }
    
    func deleteMessage(id: String) throws {
        let message = DatabaseSchema.messages.filter(DatabaseSchema.messageId == id)
        
        do {
            if try db.run(message.delete()) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Search Methods
    
    func searchConversations(query: String) -> [Conversation] {
        // Create a pattern for SQLite's LIKE operator
        let pattern = "%\(query)%"
        
        // Search in conversation titles and message content
        let titleMatches = DatabaseSchema.conversations
            .filter(DatabaseSchema.conversationTitle.like(pattern))
        
        let contentMatches = DatabaseSchema.conversations
            .join(DatabaseSchema.messages, on: DatabaseSchema.conversationId == DatabaseSchema.messageConversationId)
            .filter(DatabaseSchema.messageContent.like(pattern))
            .select(distinct: DatabaseSchema.conversationId, DatabaseSchema.conversationTitle, 
                    DatabaseSchema.conversationCreatedAt, DatabaseSchema.conversationUpdatedAt, 
                    DatabaseSchema.conversationProfileId)
        
        var conversations: [Conversation] = []
        
        do {
            print("Searching conversations for: \(query)")
            
            // Get title matches
            for row in try db.prepare(titleMatches) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    messages: [], // Don't load messages here for performance
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                conversations.append(conversation)
            }
            
            // Get content matches
            for row in try db.prepare(contentMatches) {
                let conversation = Conversation(
                    id: row[DatabaseSchema.conversationId],
                    title: row[DatabaseSchema.conversationTitle],
                    messages: [], // Don't load messages here for performance
                    createdAt: row[DatabaseSchema.conversationCreatedAt],
                    updatedAt: row[DatabaseSchema.conversationUpdatedAt],
                    profileId: row[DatabaseSchema.conversationProfileId]
                )
                
                // Only add if not already added from title matches
                if !conversations.contains(where: { $0.id == conversation.id }) {
                    conversations.append(conversation)
                }
            }
        } catch {
            print("Error searching conversations: \(error.localizedDescription)")
        }
        
        // Sort by most recently updated
        return conversations.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}
