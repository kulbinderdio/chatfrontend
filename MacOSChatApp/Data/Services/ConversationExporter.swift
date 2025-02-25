import Foundation

class ConversationExporter {
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    func exportConversation(_ conversation: Conversation, to url: URL) throws {
        // Create export data
        var exportData: [String: Any] = [
            "id": conversation.id,
            "title": conversation.title,
            "createdAt": conversation.createdAt.timeIntervalSince1970,
            "updatedAt": conversation.updatedAt.timeIntervalSince1970
        ]
        
        // Add messages
        var messagesData: [[String: Any]] = []
        
        for message in conversation.messages {
            let messageData: [String: Any] = [
                "id": message.id,
                "role": message.role,
                "content": message.content,
                "timestamp": message.timestamp.timeIntervalSince1970
            ]
            
            messagesData.append(messageData)
        }
        
        exportData["messages"] = messagesData
        
        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        
        // Write to file
        try jsonData.write(to: url)
    }
    
    func exportAllConversations(to directoryURL: URL) throws {
        // Get all conversations
        let conversations = databaseManager.getAllConversations(limit: 1000)
        
        // Create directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        // Export each conversation
        for conversation in conversations {
            let fileName = "\(conversation.id).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            try exportConversation(conversation, to: fileURL)
        }
    }
    
    func importConversation(from url: URL) throws -> Conversation {
        // Read JSON data
        let data = try Data(contentsOf: url)
        
        // Parse JSON
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String,
              let title = json["title"] as? String,
              let createdAtTimestamp = json["createdAt"] as? TimeInterval,
              let updatedAtTimestamp = json["updatedAt"] as? TimeInterval,
              let messagesData = json["messages"] as? [[String: Any]] else {
            throw ExportError.invalidFormat
        }
        
        // Create conversation
        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        let updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
        
        var messages: [Message] = []
        
        for messageData in messagesData {
            guard let id = messageData["id"] as? String,
                  let role = messageData["role"] as? String,
                  let content = messageData["content"] as? String,
                  let timestampValue = messageData["timestamp"] as? TimeInterval else {
                continue
            }
            
            let timestamp = Date(timeIntervalSince1970: timestampValue)
            
            let message = Message(
                id: id,
                role: role,
                content: content,
                timestamp: timestamp
            )
            
            messages.append(message)
        }
        
        let conversation = Conversation(
            id: id,
            title: title,
            messages: messages,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileId: nil
        )
        
        return conversation
    }
}

enum ExportError: Error {
    case invalidFormat
}
