import Foundation
import AppKit

enum ExportFormat {
    case plainText
    case markdown
    case pdf
}

class ConversationExporter {
    private let databaseManager: DatabaseManager
    
    init(databaseManager: DatabaseManager) {
        self.databaseManager = databaseManager
    }
    
    func exportConversation(id: String, format: ExportFormat) -> URL? {
        guard let conversation = databaseManager.getConversation(id: id) else {
            return nil
        }
        
        switch format {
        case .plainText:
            return exportAsPlainText(conversation: conversation)
        case .markdown:
            return exportAsMarkdown(conversation: conversation)
        case .pdf:
            return exportAsPDF(conversation: conversation)
        }
    }
    
    private func exportAsPlainText(conversation: Conversation) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let content = conversation.exportAsText()
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export conversation as plain text: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsMarkdown(conversation: Conversation) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).md"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        let content = conversation.exportAsMarkdown()
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export conversation as markdown: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportAsPDF(conversation: Conversation) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        // Create an attributed string with the conversation content
        let content = NSMutableAttributedString()
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 18)
        ]
        content.append(NSAttributedString(string: "\(conversation.title)\n\n", attributes: titleAttributes))
        
        // Date
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.gray
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        content.append(NSAttributedString(string: "Created: \(dateFormatter.string(from: conversation.createdAt))\n", attributes: dateAttributes))
        content.append(NSAttributedString(string: "Last updated: \(dateFormatter.string(from: conversation.updatedAt))\n\n", attributes: dateAttributes))
        
        // Messages
        for message in conversation.messages {
            let roleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 14)
            ]
            
            let role = message.role == "user" ? "You" : "Assistant"
            content.append(NSAttributedString(string: "\(role) - \(dateFormatter.string(from: message.timestamp))\n", attributes: roleAttributes))
            
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12)
            ]
            content.append(NSAttributedString(string: "\(message.content)\n\n", attributes: messageAttributes))
        }
        
        // Create PDF context
        guard let pdfData = createPDFData(from: content) else {
            return nil
        }
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to export conversation as PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createPDFData(from attributedString: NSAttributedString) -> Data? {
        let pdfData = NSMutableData()
        
        // Create PDF context
        guard let pdfContext = CGContext(consumer: CGDataConsumer(data: pdfData as CFMutableData)!, mediaBox: nil, nil) else {
            return nil
        }
        
        // Begin PDF page
        pdfContext.beginPDFPage(nil)
        
        // Create text frame
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let pageRect = CGRect(x: 20, y: 20, width: 572, height: 752) // US Letter size (612x792) with margins
        let path = CGPath(rect: pageRect, transform: nil)
        let frame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedString.length), path, nil)
        
        // Flip coordinates for PDF context
        pdfContext.translateBy(x: 0, y: 792)
        pdfContext.scaleBy(x: 1.0, y: -1.0)
        
        // Draw text
        CTFrameDraw(frame, pdfContext)
        
        // End PDF page and context
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
}
