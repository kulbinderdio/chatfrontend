import SwiftUI
import UniformTypeIdentifiers

struct DocumentDropArea<Content: View>: View {
    let onDocumentDropped: (URL) -> Void
    let content: () -> Content
    
    @State private var isHighlighted = false
    
    init(onDocumentDropped: @escaping (URL) -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.onDocumentDropped = onDocumentDropped
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Color.blue : Color.gray.opacity(0.5), lineWidth: isHighlighted ? 2 : 1)
                    .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
            )
            .onDrop(of: [.fileURL], isTargeted: $isHighlighted) { providers -> Bool in
                guard let provider = providers.first else { return false }
                
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url, error == nil {
                        DispatchQueue.main.async {
                            onDocumentDropped(url)
                        }
                    }
                }
                
                return true
            }
    }
}

struct DocumentDropArea_Previews: PreviewProvider {
    static var previews: some View {
        DocumentDropArea(onDocumentDropped: { _ in }) {
            Image(systemName: "doc.on.doc")
                .font(.title)
                .foregroundColor(.blue)
        }
        .frame(width: 100, height: 100)
        .previewLayout(.sizeThatFits)
    }
}
