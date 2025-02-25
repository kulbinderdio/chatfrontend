import Foundation
import SQLite

struct DatabaseSchema {
    // Conversations table
    static let conversations = Table("conversations")
    static let conversationId = Expression<String>("id")
    static let conversationTitle = Expression<String>("title")
    static let conversationCreatedAt = Expression<Date>("created_at")
    static let conversationUpdatedAt = Expression<Date>("updated_at")
    static let conversationProfileId = Expression<String?>("profile_id")
    
    // Messages table
    static let messages = Table("messages")
    static let messageId = Expression<String>("id")
    static let messageConversationId = Expression<String>("conversation_id")
    static let messageRole = Expression<String>("role")
    static let messageContent = Expression<String>("content")
    static let messageTimestamp = Expression<Date>("timestamp")
    
    // Profiles table
    static let profiles = Table("profiles")
    static let profileId = Expression<String>("id")
    static let profileName = Expression<String>("name")
    static let profileApiEndpoint = Expression<String>("api_endpoint")
    static let profileModelName = Expression<String>("model_name")
    static let profileTemperature = Expression<Double>("temperature")
    static let profileMaxTokens = Expression<Int>("max_tokens")
    static let profileTopP = Expression<Double>("top_p")
    static let profileFrequencyPenalty = Expression<Double>("frequency_penalty")
    static let profilePresencePenalty = Expression<Double>("presence_penalty")
    static let profileIsDefault = Expression<Bool>("is_default")
    
    static func createTables(db: Connection) throws {
        // Create profiles table
        try db.run(profiles.create(ifNotExists: true) { table in
            table.column(profileId, primaryKey: true)
            table.column(profileName)
            table.column(profileApiEndpoint)
            table.column(profileModelName)
            table.column(profileTemperature)
            table.column(profileMaxTokens)
            table.column(profileTopP)
            table.column(profileFrequencyPenalty)
            table.column(profilePresencePenalty)
            table.column(profileIsDefault)
        })
        
        // Create conversations table
        try db.run(conversations.create(ifNotExists: true) { table in
            table.column(conversationId, primaryKey: true)
            table.column(conversationTitle)
            table.column(conversationCreatedAt)
            table.column(conversationUpdatedAt)
            table.column(conversationProfileId)
            table.foreignKey(conversationProfileId, references: profiles, profileId, update: .cascade, delete: .setNull)
        })
        
        // Create messages table
        try db.run(messages.create(ifNotExists: true) { table in
            table.column(messageId, primaryKey: true)
            table.column(messageConversationId)
            table.column(messageRole)
            table.column(messageContent)
            table.column(messageTimestamp)
            table.foreignKey(messageConversationId, references: conversations, conversationId, update: .cascade, delete: .cascade)
        })
        
        // Create indexes
        try db.run(messages.createIndex(messageConversationId, ifNotExists: true))
        try db.run(conversations.createIndex(conversationUpdatedAt, ifNotExists: true))
    }
}
