import SwiftUI

struct DocumentDropArea<Content: View>: View {
    let onDocumentDropped: (URL) -> Void
    let content: Content
    
    @State private var isTargeted = false
    
    init(onDocumentDropped: @escaping (URL) -> Void, @ViewBuilder content: () -> Content) {
        self.onDocumentDropped = onDocumentDropped
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
            )
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool in
                providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, _ in
                    DispatchQueue.main.async {
                        if let urlData = urlData as? Data {
                            let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                            
                            // Check if file is PDF or TXT
                            let fileExtension = url.pathExtension.lowercased()
                            if fileExtension == "pdf" || fileExtension == "txt" {
                                onDocumentDropped(url)
                            }
                        }
                    }
                }
                return true
            }
            .accessibilityLabel("Document drop area")
            .accessibilityHint("Drag and drop PDF or TXT files here")
            .accessibilityAddTraits(.allowsDirectInteraction)
            .id("DocumentDropArea") // Add identifier for UI testing
    }
}
