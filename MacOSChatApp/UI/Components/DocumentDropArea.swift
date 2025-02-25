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
            .onDrop(of: ["public.file-url"], isTargeted: $isTargeted) { providers -> Bool
                providers.first?.loadItem(forTypeIdentifier: "public.file-url", options: nil) { urlData, _ in
                    DispatchQueue.main.async {
                        if let urlData = urlData as? Data {
                            let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                            
                            // Check if file is PDF or TXT
                            if url.pathExtension.lowercased() == "pdf" || url.pathExtension.lowercased() == "txt" {
                                onDocumentDropped(url)
                            }
                        }
                    }
                }
                return true
            }
    }
}

// Preview provider for SwiftUI Canvas
struct DocumentDropArea_Previews: PreviewProvider {
    static var previews: some View {
        DocumentDropArea(onDocumentDropped: { _ in }) {
            Text("Drop PDF or TXT files here")
                .frame(width: 300, height: 200)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
}
