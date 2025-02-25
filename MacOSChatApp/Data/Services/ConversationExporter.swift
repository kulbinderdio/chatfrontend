import Foundation
import AppKit
import PDFKit

class ConversationExporter {
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    func exportConversation(_ conversation: Conversation, to url: URL, format: ExportFormat) throws {
        switch format {
        case .plainText:
            try exportAsPlainText(conversation, to: url)
        case .markdown:
            try exportAsMarkdown(conversation, to: url)
        case .pdf:
            try exportAsPDF(conversation, to: url)
        case .json:
            try exportAsJSON(conversation, to: url)
        }
    }
    
    private func exportAsPlainText(_ conversation: Conversation, to url: URL) throws {
        var text = "\(conversation.title)\n"
        text += "Date: \(formatDate(conversation.createdAt))\n\n"
        
        for message in conversation.messages {
            let role = message.role == "user" ? "You" : "Assistant"
            text += "\(role): \(message.content)\n\n"
        }
        
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportAsMarkdown(_ conversation: Conversation, to url: URL) throws {
        var text = "# \(conversation.title)\n\n"
        text += "Date: \(formatDate(conversation.createdAt))\n\n"
        
        for message in conversation.messages {
            let role = message.role == "user" ? "You" : "Assistant"
            text += "**\(role)**: \(message.content)\n\n"
        }
        
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportAsPDF(_ conversation: Conversation, to url: URL) throws {
        // Create attributed string for PDF
        let title = NSAttributedString(
            string: "\(conversation.title)\n",
            attributes: [
                .font: NSFont.boldSystemFont(ofSize: 18),
                .foregroundColor: NSColor.black
            ]
        )
        
        let dateString = NSAttributedString(
            string: "Date: \(formatDate(conversation.createdAt))\n\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.darkGray
            ]
        )
        
        let content = NSMutableAttributedString()
        content.append(title)
        content.append(dateString)
        
        for message in conversation.messages {
            let role = message.role == "user" ? "You" : "Assistant"
            let roleString = NSAttributedString(
                string: "\(role): ",
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: NSColor.black
                ]
            )
            
            let messageString = NSAttributedString(
                string: "\(message.content)\n\n",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 14),
                    .foregroundColor: NSColor.black
                ]
            )
            
            content.append(roleString)
            content.append(messageString)
        }
        
        // Create PDF document
        let pdfDocument = PDFDocument()
        
        // Create a PDF page
        let pdfPage = PDFPage()
        
        // Create text view to render content
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 612 - 72, height: 792 - 72))
        textView.textStorage?.setAttributedString(content)
        
        // Add the text view to the PDF page
        pdfDocument.insert(pdfPage, at: 0)
        
        // Save PDF to file
        pdfDocument.write(to: url)
    }
    
    private func exportAsJSON(_ conversation: Conversation, to url: URL) throws {
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
            
            try exportConversation(conversation, to: fileURL, format: .json)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

public enum ExportFormat {
    case plainText
    case markdown
    case pdf
    case json
}

enum ExportError: Error {
    case invalidFormat
    case pdfCreationFailed
}
