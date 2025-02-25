import Foundation
import Combine
import UniformTypeIdentifiers
import QuickLook

class DocumentHandler: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    
    // Supported file types
    private let supportedTypes: [UTType] = [
        .plainText,
        .pdf,
        .rtf,
        .html,
        .json,
        .xml,
        .yaml,
        .text
    ]
    
    // Check if a file type is supported
    func isSupported(fileType: UTType) -> Bool {
        return supportedTypes.contains { fileType.conforms(to: $0) }
    }
    
    // Process a single document
    func processDocument(_ url: URL) -> Result<String, Error> {
        guard url.startAccessingSecurityScopedResource() else {
            return .failure(DocumentError.accessDenied)
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let fileType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
            
            guard let type = fileType, isSupported(fileType: type) else {
                return .failure(DocumentError.unsupportedFileType)
            }
            
            if type.conforms(to: .plainText) || type.conforms(to: .text) {
                // Handle text files
                let content = try String(contentsOf: url, encoding: .utf8)
                return .success(content)
            } else if type.conforms(to: .pdf) {
                // Handle PDF files
                return extractTextFromPDF(url: url)
            } else if type.conforms(to: .rtf) {
                // Handle RTF files
                return extractTextFromRTF(url: url)
            } else {
                return .failure(DocumentError.unsupportedFileType)
            }
        } catch {
            return .failure(error)
        }
    }
    
    // Process multiple documents
    func processDocuments(_ urls: [URL], completion: @escaping (Result<String, Error>) -> Void) {
        isProcessing = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(DocumentError.unknown))
                }
                return
            }
            
            var combinedContent = ""
            
            for url in urls {
                let result = self.processDocument(url)
                
                switch result {
                case .success(let content):
                    combinedContent += "--- \(url.lastPathComponent) ---\n\n"
                    combinedContent += content
                    combinedContent += "\n\n"
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(.success(combinedContent))
            }
        }
    }
    
    // Extract text from PDF
    private func extractTextFromPDF(url: URL) -> Result<String, Error> {
        guard let pdf = CGPDFDocument(url as CFURL) else {
            return .failure(DocumentError.pdfParsingError)
        }
        
        var text = ""
        
        for i in 1...pdf.numberOfPages {
            guard let page = pdf.page(at: i) else { continue }
            
            let pageText = extractTextFromPDFPage(page)
            text += pageText
            text += "\n\n"
        }
        
        return .success(text)
    }
    
    // Extract text from a PDF page
    private func extractTextFromPDFPage(_ page: CGPDFPage) -> String {
        // This is a simplified implementation
        // In a real app, we would use PDFKit or a third-party library
        return "PDF content (page \(page.pageNumber))"
    }
    
    // Extract text from RTF
    private func extractTextFromRTF(url: URL) -> Result<String, Error> {
        do {
            let data = try Data(contentsOf: url)
            
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                return .success(attributedString.string)
            } else {
                return .failure(DocumentError.rtfParsingError)
            }
        } catch {
            return .failure(error)
        }
    }
}

enum DocumentError: Error, LocalizedError {
    case accessDenied
    case unsupportedFileType
    case pdfParsingError
    case rtfParsingError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to the document was denied"
        case .unsupportedFileType:
            return "The file type is not supported"
        case .pdfParsingError:
            return "Failed to parse PDF document"
        case .rtfParsingError:
            return "Failed to parse RTF document"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
