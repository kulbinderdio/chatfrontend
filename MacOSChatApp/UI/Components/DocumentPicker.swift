import SwiftUI
import AppKit

struct DocumentPicker: NSViewRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .plainText]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                onDocumentPicked(url)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
