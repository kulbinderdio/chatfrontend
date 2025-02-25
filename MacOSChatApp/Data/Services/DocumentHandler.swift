import Foundation
import PDFKit
import Combine

enum DocumentHandlerError: Error {
    case unsupportedFileType
    case fileReadError
    case pdfProcessingError
    case emptyDocument
}

class DocumentHandler: ObservableObject {
    func extractText(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try extractTextFromPDF(url: url)
        case "txt":
            return try extractTextFromTXT(url: url)
        default:
            throw DocumentHandlerError.unsupportedFileType
        }
    }
    
    private func extractTextFromPDF(url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentHandlerError.pdfProcessingError
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            if let pageText = page.string {
                extractedText += pageText
                
                // Add a newline between pages
                if pageIndex < pdfDocument.pageCount - 1 {
                    extractedText += "\n\n"
                }
            }
        }
        
        if extractedText.isEmpty {
            throw DocumentHandlerError.emptyDocument
        }
        
        return preprocessText(extractedText)
    }
    
    private func extractTextFromTXT(url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            
            // Try to detect encoding
            let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .utf16]
            
            for encoding in encodings {
                if let text = String(data: data, encoding: encoding) {
                    if !text.isEmpty {
                        return preprocessText(text)
                    }
                }
            }
            
            throw DocumentHandlerError.fileReadError
        } catch {
            throw DocumentHandlerError.fileReadError
        }
    }
    
    private func preprocessText(_ text: String) -> String {
        // Normalize whitespace
        var processedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        
        // Remove excessive newlines (more than 2 consecutive)
        processedText = processedText.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // Trim whitespace
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Rough estimation: 1 token ≈ 4 characters for English text
        return text.count / 4
    }
}
