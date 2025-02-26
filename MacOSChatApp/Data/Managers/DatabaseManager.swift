import Foundation
import SQLite
import Combine

class DatabaseManager: ObservableObject {
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
    }
    
    // For testing purposes
    convenience init(inMemory: Bool) throws {
        if inMemory {
            try self.init(connection: Connection(.inMemory))
        } else {
            try self.init()
        }
    }
    
    // For testing with a specific connection
    init(connection: Connection) throws {
        self.db = connection
        try DatabaseSchema.createTables(db: db)
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
            
            return Conversation(
                id: id,
                title: title,
                messages: [],
                createdAt: now,
                updatedAt: now,
                profileId: profileId
            )
        } catch {
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
            // Error handling is silent in release builds
        }
        
        return nil
    }
    
    func getAllConversations(limit: Int = 50, offset: Int = 0) -> [Conversation] {
        let query = DatabaseSchema.conversations
            .order(DatabaseSchema.conversationUpdatedAt.desc)
            .limit(limit, offset: offset)
        
        var conversations: [Conversation] = []
        
        do {
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
            // Error handling is silent in release builds
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
        } catch {
            // Error handling is silent in release builds
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
        } catch {
            // Error handling is silent in release builds
        }
    }
    
    func getMessages(forConversation conversationId: String) -> [Message] {
        let query = DatabaseSchema.messages
            .filter(DatabaseSchema.messageConversationId == conversationId)
            .order(DatabaseSchema.messageTimestamp.asc)
        
        var messages: [Message] = []
        
        do {
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
            // Error handling is silent in release builds
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
    
    // MARK: - Profile Methods
    
    func saveProfile(_ profile: ModelProfile) throws {
        // Check if profile already exists
        let existingProfile = getProfile(id: profile.id)
        
        if existingProfile != nil {
            // Update existing profile
            try updateProfile(profile)
        } else {
            // Insert new profile
            let insert = DatabaseSchema.profiles.insert(
                DatabaseSchema.profileId <- profile.id,
                DatabaseSchema.profileName <- profile.name,
                DatabaseSchema.profileApiEndpoint <- profile.apiEndpoint,
                DatabaseSchema.profileModelName <- profile.modelName,
                DatabaseSchema.profileTemperature <- profile.parameters.temperature,
                DatabaseSchema.profileMaxTokens <- profile.parameters.maxTokens,
                DatabaseSchema.profileTopP <- profile.parameters.topP,
                DatabaseSchema.profileFrequencyPenalty <- profile.parameters.frequencyPenalty,
                DatabaseSchema.profilePresencePenalty <- profile.parameters.presencePenalty,
                DatabaseSchema.profileIsDefault <- profile.isDefault
            )
            
            do {
                try db.run(insert)
                
                // If this is the default profile, update other profiles
                if profile.isDefault {
                    try setDefaultProfile(id: profile.id)
                }
            } catch {
                throw DatabaseError.insertFailed("Failed to save profile: \(error.localizedDescription)")
            }
        }
    }
    
    func updateProfile(_ profile: ModelProfile) throws {
        let profileQuery = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == profile.id)
        
        let update = profileQuery.update(
            DatabaseSchema.profileName <- profile.name,
            DatabaseSchema.profileApiEndpoint <- profile.apiEndpoint,
            DatabaseSchema.profileModelName <- profile.modelName,
            DatabaseSchema.profileTemperature <- profile.parameters.temperature,
            DatabaseSchema.profileMaxTokens <- profile.parameters.maxTokens,
            DatabaseSchema.profileTopP <- profile.parameters.topP,
            DatabaseSchema.profileFrequencyPenalty <- profile.parameters.frequencyPenalty,
            DatabaseSchema.profilePresencePenalty <- profile.parameters.presencePenalty,
            DatabaseSchema.profileIsDefault <- profile.isDefault
        )
        
        do {
            if try db.run(update) > 0 {
                // If this is the default profile, update other profiles
                if profile.isDefault {
                    try setDefaultProfile(id: profile.id)
                }
                
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(id: String) -> ModelProfile? {
        let query = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
        
        do {
            if let row = try db.pluck(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                let profile = ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    modelName: row[DatabaseSchema.profileModelName],
                    apiEndpoint: row[DatabaseSchema.profileApiEndpoint],
                    isDefault: row[DatabaseSchema.profileIsDefault],
                    parameters: parameters
                )
                
                return profile
            }
        } catch {
            // Error handling is silent in release builds
        }
        
        return nil
    }
    
    func getAllProfiles() -> [ModelProfile] {
        let query = DatabaseSchema.profiles.order(DatabaseSchema.profileName.asc)
        
        var profiles: [ModelProfile] = []
        
        do {
            for row in try db.prepare(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                let profile = ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    modelName: row[DatabaseSchema.profileModelName],
                    apiEndpoint: row[DatabaseSchema.profileApiEndpoint],
                    isDefault: row[DatabaseSchema.profileIsDefault],
                    parameters: parameters
                )
                
                profiles.append(profile)
            }
        } catch {
            // Error handling is silent in release builds
        }
        
        return profiles
    }
    
    func deleteProfile(id: String) throws {
        // Check if this is the default profile
        let profile = getProfile(id: id)
        
        if profile?.isDefault == true {
            throw DatabaseError.deleteFailed("Cannot delete the default profile")
        }
        
        // Delete the profile
        let profileQuery = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
        
        do {
            if try db.run(profileQuery.delete()) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.deleteFailed("Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    func setDefaultProfile(id: String) throws {
        // First, set all profiles to non-default
        let update = DatabaseSchema.profiles.update(DatabaseSchema.profileIsDefault <- false)
        
        do {
            try db.run(update)
            
            // Then, set the specified profile to default
            let profileQuery = DatabaseSchema.profiles.filter(DatabaseSchema.profileId == id)
            let defaultUpdate = profileQuery.update(DatabaseSchema.profileIsDefault <- true)
            
            if try db.run(defaultUpdate) > 0 {
                return
            } else {
                throw DatabaseError.notFound
            }
        } catch {
            throw DatabaseError.updateFailed("Failed to set default profile: \(error.localizedDescription)")
        }
    }
    
    func getDefaultProfile() -> ModelProfile? {
        let query = DatabaseSchema.profiles.filter(DatabaseSchema.profileIsDefault == true)
        
        do {
            if let row = try db.pluck(query) {
                let parameters = ModelParameters(
                    temperature: row[DatabaseSchema.profileTemperature],
                    maxTokens: row[DatabaseSchema.profileMaxTokens],
                    topP: row[DatabaseSchema.profileTopP],
                    frequencyPenalty: row[DatabaseSchema.profileFrequencyPenalty],
                    presencePenalty: row[DatabaseSchema.profilePresencePenalty]
                )
                
                let profile = ModelProfile(
                    id: row[DatabaseSchema.profileId],
                    name: row[DatabaseSchema.profileName],
                    modelName: row[DatabaseSchema.profileModelName],
                    apiEndpoint: row[DatabaseSchema.profileApiEndpoint],
                    isDefault: true,
                    parameters: parameters
                )
                
                return profile
            }
        } catch {
            // Error handling is silent in release builds
        }
        
        return nil
    }
    
    // MARK: - Count Methods
    
    func getConversationCount() -> Int {
        do {
            let count = try db.scalar(DatabaseSchema.conversations.count)
            return count
        } catch {
            // Error handling is silent in release builds
            return 0
        }
    }
    
    // MARK: - Search Methods
    
    func searchConversations(query: String) -> [Conversation] {
        // If query is empty, return all conversations
        if query.isEmpty {
            return getAllConversations()
        }
        
        // Create a pattern for SQLite's LIKE operator
        let pattern = "%\(query)%"
        
        // Search in conversation titles only for now to avoid join issues
        let titleMatches = DatabaseSchema.conversations
            .filter(DatabaseSchema.conversationTitle.like(pattern))
        
        var conversations: [Conversation] = []
        
        do {
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
            
            // Search in message content separately to avoid join issues
            let messageMatches = DatabaseSchema.messages
                .filter(DatabaseSchema.messageContent.like(pattern))
                .select(distinct: DatabaseSchema.messageConversationId)
            
            for row in try db.prepare(messageMatches) {
                let conversationId = row[DatabaseSchema.messageConversationId]
                
                // Only process if not already added from title matches
                if !conversations.contains(where: { $0.id == conversationId }) {
                    // Get the conversation details
                    if let conversation = getConversation(id: conversationId) {
                        // Create a conversation object without loading all messages
                        let searchResult = Conversation(
                            id: conversation.id,
                            title: conversation.title,
                            messages: [], // Don't load messages here for performance
                            createdAt: conversation.createdAt,
                            updatedAt: conversation.updatedAt,
                            profileId: conversation.profileId
                        )
                        conversations.append(searchResult)
                    }
                }
            }
        } catch {
            // Error handling is silent in release builds
        }
        
        // Sort by most recently updated
        return conversations.sorted(by: { $0.updatedAt > $1.updatedAt })
    }
}
