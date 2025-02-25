import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let role: String // "user", "assistant", "system"
    let content: String
    let timestamp: Date
    
    init(id: String, role: String, content: String, timestamp: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    // Convenience initializer with auto-generated ID
    init(role: String, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
    }
    
    // Equatable conformance
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id &&
               lhs.role == rhs.role &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp
    }
}

// Extension for OpenAI API compatibility
extension Message {
    var apiRepresentation: [String: String] {
        return [
            "role": role,
            "content": content
        ]
    }
    
    static func fromAPIResponse(id: String, role: String, content: String) -> Message {
        return Message(id: id, role: role, content: content, timestamp: Date())
    }
}
