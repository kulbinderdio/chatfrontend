import Foundation
import PDFKit

class DocumentHandler {
    // MARK: - Document Extraction
    
    func extractText(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try extractTextFromPDF(url: url)
        case "txt":
            return try extractTextFromTXT(url: url)
        default:
            throw DocumentError.unsupportedFileType
        }
    }
    
    private func extractTextFromPDF(url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentError.invalidPDF
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            
            if let pageText = page.string {
                extractedText += pageText
                
                // Add a newline if this isn't the last page
                if pageIndex < pdfDocument.pageCount - 1 {
                    extractedText += "\n\n"
                }
            }
        }
        
        return extractedText
    }
    
    private func extractTextFromTXT(url: URL) throws -> String {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try other encodings if UTF-8 fails
            do {
                return try String(contentsOf: url, encoding: .ascii)
            } catch {
                throw DocumentError.invalidTextFile
            }
        }
    }
    
    // MARK: - Token Estimation
    
    func estimateTokenCount(for text: String) -> Int {
        // This is a very rough estimation
        // In a real implementation, we would use a more accurate method
        // OpenAI's tokenizer uses about 4 characters per token on average
        
        let characterCount = text.count
        return characterCount / 4
    }
    
    // MARK: - Error Handling
    
    enum DocumentError: Error, LocalizedError {
        case unsupportedFileType
        case invalidPDF
        case invalidTextFile
        case extractionFailed
        
        var errorDescription: String? {
            switch self {
            case .unsupportedFileType:
                return "Unsupported file type. Only PDF and TXT files are supported."
            case .invalidPDF:
                return "Invalid PDF file. The file could not be read."
            case .invalidTextFile:
                return "Invalid text file. The file could not be read."
            case .extractionFailed:
                return "Failed to extract text from the document."
            }
        }
    }
}
