import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String, title: String, messages: [Message], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convenience initializer with auto-generated ID
    init(title: String, messages: [Message] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case messages
        case createdAt
        case updatedAt
    }
    
    // Equatable conformance
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.messages == rhs.messages &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt
    }
    
    // Update the conversation with a new message
    mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
    }
    
    // Generate a title based on the first user message
    mutating func generateTitle() {
        if let firstUserMessage = messages.first(where: { $0.role == "user" }) {
            let content = firstUserMessage.content
            let maxLength = 30
            
            if content.count <= maxLength {
                title = content
            } else {
                let endIndex = content.index(content.startIndex, offsetBy: maxLength)
                title = String(content[..<endIndex]) + "..."
            }
        } else {
            title = "New Conversation"
        }
    }
}

// Extension for export functionality
extension Conversation {
    func exportAsText() -> String {
        var result = "\(title)\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        result += "Created: \(dateFormatter.string(from: createdAt))\n"
        result += "Last updated: \(dateFormatter.string(from: updatedAt))\n\n"
        
        for message in messages {
            let role = message.role == "user" ? "You" : "Assistant"
            let timestamp = dateFormatter.string(from: message.timestamp)
            
            result += "[\(role) - \(timestamp)]\n"
            result += message.content
            result += "\n\n"
        }
        
        return result
    }
    
    func exportAsMarkdown() -> String {
        var result = "# \(title)\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        result += "*Created: \(dateFormatter.string(from: createdAt))*\n"
        result += "*Last updated: \(dateFormatter.string(from: updatedAt))*\n\n"
        
        for message in messages {
            let role = message.role == "user" ? "You" : "Assistant"
            let timestamp = dateFormatter.string(from: message.timestamp)
            
            result += "### \(role) - \(timestamp)\n\n"
            result += message.content
            result += "\n\n"
        }
        
        return result
    }
}
